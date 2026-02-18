# OpenClaw Security Integration Guide

This guide explains how to integrate the hardened security modules into the base OpenClaw codebase.

---

## 📂 File Structure Overview

```
openclaw-hardened/
├── auth/                           (NEW - Security modules)
│   ├── dual-password-gate.ts
│   ├── password-delivery-gmail.ts
│   ├── password-delivery-telegram.ts
│   └── draft-enforcer.ts
├
├── security/                       (NEW - Security modules)
│   ├── injection-filter.ts
│   └── single-owner-guard.ts
├── config/                         (NEW - Configuration)
│   └── hardened-config.ts
├── docker/                         (NEW - Docker setup)
│   ├── Dockerfile.hardened
│   └── docker-compose.yml
├── src/                            (OpenClaw core - MODIFY)
│   ├── gateway/
│   │   └── index.ts               (← MODIFY THIS)
│   ├── tools/
│   │   └── tool-executor.ts       (← MODIFY THIS)
│   └── agents/
│       └── agent-runner.ts        (← MODIFY THIS)
└── package.json                    (← ADD DEPENDENCIES)
```

---

## 🔧 Step 1: Add Dependencies

### Edit `package.json`

Add these dependencies to the `dependencies` section:

```json
{
  "dependencies": {
    "nodemailer": "^6.9.7",
    "node-fetch": "^3.3.2"
  }
}
```

Then run:
```bash
npm install
```

---

## 🔧 Step 2: Modify Gateway Entry Point

### File: `src/gateway/index.ts`

Add these imports at the top:

```typescript
import { dualPasswordGate } from '../auth/dual-password-gate';
import { singleOwnerGuard } from '../security/single-owner-guard';
import { promptInjectionFilter } from '../security/injection-filter';
import { HARDENED_CONFIG } from '../config/hardened-config';
```

Add initialization on gateway startup (look for the `start()` or `initialize()` function):

```typescript
async function start() {
  // Existing code...
  
  // Initialize security systems
  console.log('[Security] Initializing hardened security systems...');
  console.log('[Security] Owner:', HARDENED_CONFIG.owner.email);
  console.log('[Security] Dual-auth:', HARDENED_CONFIG.security.dualAuth.enabled ? 'ENABLED' : 'DISABLED');
  console.log('[Security] Draft mode:', HARDENED_CONFIG.security.draftMode.enabled ? 'ENABLED' : 'DISABLED');
  console.log('[Security] Injection defense:', HARDENED_CONFIG.security.injectionDefense.enabled ? 'ENABLED' : 'DISABLED');
  
  // Existing gateway startup code...
}
```

---

## 🔧 Step 3: Hook Into Tool Execution

### File: `src/tools/tool-executor.ts`

Wrap tool execution with security checks:

```typescript
import { enforceDraftApproval } from '../auth/draft-enforcer';
import { enforceOwnerOnly } from '../security/single-owner-guard';
import { promptInjectionFilter } from '../security/injection-filter';
import { HARDENED_CONFIG } from '../config/hardened-config';

// Find the tool execution function (might be called executeTool, invokeTool, etc.)
async function executeTool(toolName: string, params: any, context: any) {
  // STEP 1: Verify owner authorization
  const source = context.source || 'unknown';
  const metadata = {
    email: context.user?.email,
    phone: context.user?.phone,
    telegramId: context.user?.telegramId
  };
  
  try {
    await enforceOwnerOnly(
      `Execute ${toolName}`,
      source,
      metadata
    );
  } catch (error) {
    console.error('[Security] Command rejected:', error.message);
    return {
      error: true,
      message: 'Access denied. Only the owner can issue commands.'
    };
  }
  
  // STEP 2: Check if this is a write action (requires draft approval)
  if (HARDENED_CONFIG.security.draftMode.enabled) {
    return await enforceDraftApproval(
      toolName,
      params,
      async () => {
        // Original tool execution
        return await originalToolExecute(toolName, params, context);
      }
    );
  }
  
  // STEP 3: Execute normally (read-only actions)
  return await originalToolExecute(toolName, params, context);
}

// Keep the original execution logic
async function originalToolExecute(toolName: string, params: any, context: any) {
  // Original OpenClaw tool execution code
  // ...existing code...
}
```

---

## 🔧 Step 4: Filter External Content

### File: `src/agents/agent-runner.ts`

Add content filtering before sending to LLM:

```typescript
import { promptInjectionFilter } from '../security/injection-filter';
import { logInjectionAttempt } from '../security/injection-filter';

// Find where external content (emails, web pages, files) is processed
function prepareContextForLLM(messages: any[], externalContent: any[]) {
  // Filter and wrap all external content
  const filteredContent = externalContent.map(item => {
    const sanitized = promptInjectionFilter.sanitize(item.content, item.source);
    
    // Log if threats detected
    if (sanitized.flagged) {
      logInjectionAttempt(item.source, sanitized.threats, item.content);
    }
    
    // Block high-confidence threats
    if (promptInjectionFilter.shouldBlockContent(sanitized)) {
      console.error(`[Security] BLOCKED high-confidence injection attempt from ${item.source}`);
      return {
        ...item,
        content: '[BLOCKED: Security threat detected]'
      };
    }
    
    // Wrap in safety tags
    return {
      ...item,
      content: promptInjectionFilter.wrapExternalContent(
        sanitized.content,
        item.source
      )
    };
  });
  
  // Continue with existing context preparation
  return buildLLMContext(messages, filteredContent);
}
```

---

## 🔧 Step 5: Add Draft Management Commands

### File: `src/gateway/commands.ts` (or wherever commands are registered)

Add these commands:

```typescript
import { draftEnforcer } from '../auth/draft-enforcer';
import { dualPasswordGate } from '../auth/dual-password-gate';

// Command: /drafts
async function handleDraftsCommand(context: any) {
  const drafts = await draftEnforcer.listPendingDrafts();
  
  if (drafts.length === 0) {
    return 'No pending drafts.';
  }
  
  let message = `📝 Pending Drafts (${drafts.length}):\n\n`;
  
  for (const draft of drafts) {
    message += `• ${draft.taskId}\n`;
    message += `  Action: ${draft.actionType}\n`;
    message += `  Created: ${draft.createdAt.toLocaleString()}\n\n`;
  }
  
  return message;
}

// Command: /publish <taskId> <passwordA> <passwordB>
async function handlePublishCommand(taskId: string, passwordA: string, passwordB: string) {
  const result = await draftEnforcer.publishDraft(taskId, passwordA, passwordB);
  
  if (result.success) {
    return `✅ Draft published successfully!\n\nTask ID: ${taskId}`;
  } else {
    return `❌ Failed to publish: ${result.error}`;
  }
}

// Register commands
registerCommand('/drafts', handleDraftsCommand);
registerCommand('/publish', handlePublishCommand);
```

---

## 🔧 Step 6: Environment Configuration

### File: `.env`

Create this file in the root directory with your credentials:

```env
# Owner
OWNER_EMAIL=thrivelo.ceo@gmail.com
OWNER_TELEGRAM=+19023172861

# Gmail
GMAIL_USER=thrivelo.ceo@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx

# Telegram
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_OWNER_CHAT_ID=123456789

# Claude API
ANTHROPIC_API_KEY=sk-ant-xxxxx

# Security
SECURITY_MODE=hardened
DRAFT_MODE=enabled
```

---

## 🔧 Step 7: TypeScript Configuration

### File: `tsconfig.json`

Ensure these paths are included:

```json
{
  "compilerOptions": {
    "paths": {
      "@/auth/*": ["./auth/*"],
      "@/security/*": ["./security/*"],
      "@/config/*": ["./config/*"]
    }
  },
  "include": [
    "src/**/*",
    "auth/**/*",
    "security/**/*",
    "config/**/*"
  ]
}
```

---

## 🔧 Step 8: Build & Deploy

### Build TypeScript

```bash
npm run build
```

### Run with Docker

```bash
docker-compose -f docker/docker-compose.yml up -d
```

### Run Locally (for testing)

```bash
npm start
```

---

## ✅ Verification Checklist

After integration, verify:

1. **Dual-password system works:**
   - ✅ Initiation passwords sent to Gmail + Telegram
   - ✅ Task starts only after both passwords entered
   - ✅ Completion passwords sent for final approval

2. **Draft enforcement works:**
   - ✅ All write actions create drafts
   - ✅ Nothing publishes without password approval
   - ✅ `/drafts` command shows pending items

3. **Owner-only access works:**
   - ✅ Commands from owner's Telegram accepted
   - ✅ Commands from other sources blocked
   - ✅ Email/message scanning blocked

4. **Injection defense works:**
   - ✅ Suspicious patterns detected and logged
   - ✅ High-confidence threats blocked
   - ✅ External content wrapped in safety tags

5. **Weekly rotation works:**
   - ✅ Rotation scheduled for next Sunday
   - ✅ Old passwords invalidated after rotation
   - ✅ Notification sent to owner

---

## 🐛 Debugging Tips

### Check Security Logs

```bash
docker-compose logs openclaw-hardened | grep Security
docker-compose logs openclaw-hardened | grep InjectionFilter
docker-compose logs openclaw-hardened | grep OwnerGuard
docker-compose logs openclaw-hardened | grep DraftEnforcer
```

### Test Password Delivery

Create a test file: `test-passwords.ts`

```typescript
import { sendPasswordViaGmail } from './auth/password-delivery-gmail';
import { sendPasswordViaTelegram } from './auth/password-delivery-telegram';

async function test() {
  console.log('Testing Gmail delivery...');
  await sendPasswordViaGmail({
    to: 'thrivelo.ceo@gmail.com',
    passwordType: 'TEST',
    password: 'TestPass123',
    taskId: 'test-001'
  });
  
  console.log('Testing Telegram delivery...');
  await sendPasswordViaTelegram({
    phoneNumber: '+19023172861',
    passwordType: 'TEST',
    password: 'TestPass456',
    taskId: 'test-001'
  });
  
  console.log('✅ Tests complete!');
}

test();
```

Run: `npx ts-node test-passwords.ts`

---

## 📞 Need Help?

Common issues:

1. **"Cannot find module '@/auth/...'"**
   - Check tsconfig.json paths
   - Rebuild: `npm run build`

2. **"Gmail authentication failed"**
   - Verify 2FA is enabled
   - Use App Password, not regular password
   - Remove spaces from password in .env

3. **"Telegram bot not responding"**
   - Click START in bot chat first
   - Verify Bot Token is correct
   - Check Chat ID matches your user ID

4. **"Drafts not saving"**
   - Check file permissions
   - Ensure `/data/drafts` directory exists
   - Check Docker volume mounts

---

## 🎉 Integration Complete!

Your OpenClaw is now hardened with:
- Dual-password authentication
- Draft-only enforcement
- Single-owner access control
- 8-layer prompt injection defense
- Complete audit logging

**Security is now MAXED OUT.** 🔒
