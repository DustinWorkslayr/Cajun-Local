# Cajun Local — Messaging & Business FAQs Cheat Sheet

> Technical reference for the 3 tables added to support user↔business messaging and business FAQ listings.
> Last updated: 2026-02-21

---

## 1. Tables (3)

### 1.1 `conversations` — Thread between a user and a business

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| business_id | uuid | No | — | FK → `businesses(id)` ON DELETE CASCADE |
| user_id | uuid | No | — | The customer who initiated |
| subject | text | Yes | — | Optional subject line |
| is_archived | boolean | No | false | Either party can archive |
| last_message_at | timestamptz | Yes | `now()` | For sort ordering |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**Constraint**: `UNIQUE (business_id, user_id)` — one conversation per user per business.

**RLS**:
- SELECT: Own user OR business manager OR admin
- INSERT: Own user (`user_id = auth.uid()`)
- UPDATE: Own user OR business manager OR admin
- DELETE: Admin only

**Indexes**: `idx_conversations_business_id`, `idx_conversations_user_id`, `idx_conversations_last_message_at`

---

### 1.2 `messages` — Individual messages within a conversation

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| conversation_id | uuid | No | — | FK → `conversations(id)` ON DELETE CASCADE |
| sender_id | uuid | No | — | The user who sent the message |
| body | text | No | — | Message content |
| is_read | boolean | No | false | Recipient marks as read |
| created_at | timestamptz | No | `now()` | |

**RLS**:
- SELECT: Participants of the conversation (user or business manager) OR admin
- INSERT: `sender_id = auth.uid()` AND must be a participant of the conversation
- UPDATE: Participants (for marking `is_read`)
- ALL: Admin

**Indexes**: `idx_messages_conversation_id`, `idx_messages_sender_id`, `idx_messages_created_at` (composite: conversation_id + created_at DESC)

---

### 1.3 `business_faqs` — FAQ entries per business listing

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| business_id | uuid | No | — | FK → `businesses(id)` ON DELETE CASCADE |
| question | text | No | — | |
| answer | text | No | — | |
| sort_order | integer | No | 0 | Display ordering |
| is_published | boolean | No | true | Only published FAQs visible to public |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**RLS**:
- SELECT: Published FAQs are public; unpublished visible to business manager + admin
- ALL (INSERT/UPDATE/DELETE): Business manager OR admin

**Index**: `idx_business_faqs_business_id`

---

## 2. Security Summary

### RLS Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `conversations` | own user OR manager OR admin | own user | own user OR manager OR admin | admin |
| `messages` | conversation participant OR admin | conversation participant | conversation participant | admin |
| `business_faqs` | published=public; unpublished=manager/admin | manager OR admin | manager OR admin | manager OR admin |

### Data Access Notes

- **Messages are scoped to conversations** — you can only read/write messages if you're the user or a manager of the business in that conversation.
- **Business FAQs** use `is_published` for visibility control instead of the `approval_status` enum (no admin moderation required for FAQs).
- **No DELETE policy** exists for regular users on conversations — only admins can delete conversation threads.

---

## 3. Triggers

| Trigger | Table | Function |
|---|---|---|
| `update_conversations_updated_at` | conversations | `update_updated_at_column()` |
| `update_business_faqs_updated_at` | business_faqs | `update_updated_at_column()` |

---

## 4. Integration with Existing Schema

These 3 tables (conversations, messages, business_faqs) plus form_submissions are part of the full backend schema. See [Backend Cheat Sheet](./backend-cheatsheet.md) for total table count.

**Foreign key relationships:**
- `conversations.business_id` → `businesses(id)`
- `messages.conversation_id` → `conversations(id)`
- `business_faqs.business_id` → `businesses(id)`

**RLS functions reused:**
- `public.has_role(uuid, app_role)` — admin checks
- `public.is_business_manager(uuid, uuid)` — business ownership checks

**No existing columns modified. No existing tables altered.**

---

## 5. Contact Form System (template-based)

### 5.1 `businesses.contact_form_template` (column)

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| contact_form_template | text | Yes | null | One of: `general_inquiry`, `appointment_request`, `quote_request`, `event_booking`. Null = no contact form shown. |

**RLS:** Same as `businesses` (approved = public read; manager/admin write).

### 5.2 `form_submissions` — User submissions to a business

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| business_id | uuid | No | — | FK → `businesses(id)` ON DELETE CASCADE |
| user_id | uuid | Yes | — | Submitter (auth.uid()); nullable if submission is anonymous |
| template | text | No | — | Same values as contact_form_template |
| data | jsonb | No | `'{}'` | Submitted field values |
| is_read | boolean | No | false | Manager marks as read |
| created_at | timestamptz | No | `now()` | |

**RLS:**
- SELECT: Business manager (for that business_id) OR admin
- INSERT: Authenticated user (user_id = auth.uid())
- UPDATE: Business manager OR admin (e.g. set is_read)
- DELETE: Admin only

**Indexes:** `idx_form_submissions_business_id`, `idx_form_submissions_created_at` (DESC)

### 5.3 Template field definitions (app-defined)

Templates and their fields are defined in app code (e.g. `ContactFormTemplates` in Dart). No DB table. Keys: `general_inquiry`, `appointment_request`, `quote_request`, `event_booking`. Each template has a list of fields (key, label, type, required).