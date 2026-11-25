# Volcengine Video / TTS Provider Contract

## 1. Purpose

This document is the handoff contract for the first real AI provider integration:

```text
volcengine-video -> Volcengine Ark/Seedance image-to-video
volcengine-tts   -> Volcengine text-to-speech
```

The implementation is provider-specific on the backend, but request paths and
response paths remain configuration values because they must be copied from the
official Volcengine console/API documentation. Do not guess or hardcode vendor
paths in Java.

## 2. Runtime Flow

```text
Flutter /api/creation/*
  -> Harness creates AiTask
  -> volcengine-video submit()
  -> providerTaskId stored on AiTask
  -> AsyncProviderPoller calls query()
  -> TaskStateService marks SUCCESS / FAILED
  -> existing /api/tasks/{id} and submission flow continue
```

Audio may return audio bytes/base64 or an audio URL directly. If the official
TTS API is asynchronous, its task ID follows the same polling path.

## 3. Environment Configuration

Secrets must be supplied through server environment variables. They must never
be committed to Git or sent to Flutter/admin-web.

### Video

```text
OPC_PROVIDER_VOLCENGINE_VIDEO_ENABLED
OPC_PROVIDER_VOLCENGINE_VIDEO_BASE_URL
OPC_PROVIDER_VOLCENGINE_VIDEO_API_KEY
OPC_PROVIDER_VOLCENGINE_VIDEO_REGION
OPC_PROVIDER_VOLCENGINE_VIDEO_MODEL
OPC_PROVIDER_VOLCENGINE_VIDEO_CREATE_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_QUERY_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_CANCEL_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_HEADERS_JSON
OPC_PROVIDER_VOLCENGINE_VIDEO_REQUEST_BODY_JSON
OPC_PROVIDER_VOLCENGINE_VIDEO_QUERY_BODY_JSON
OPC_PROVIDER_VOLCENGINE_VIDEO_AUTH_HEADER_NAME
OPC_PROVIDER_VOLCENGINE_VIDEO_AUTH_HEADER_PREFIX
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_TASK_ID_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_STATUS_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_PROGRESS_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_RESULT_URL_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_THUMB_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_RESPONSE_ERROR_PATH
OPC_PROVIDER_VOLCENGINE_VIDEO_PROCESSING_STATUSES
OPC_PROVIDER_VOLCENGINE_VIDEO_SUCCESS_STATUSES
OPC_PROVIDER_VOLCENGINE_VIDEO_FAILURE_STATUSES
OPC_PROVIDER_VOLCENGINE_VIDEO_TIMEOUT_SECONDS
```

### TTS

```text
OPC_PROVIDER_VOLCENGINE_TTS_ENABLED
OPC_PROVIDER_VOLCENGINE_TTS_BASE_URL
OPC_PROVIDER_VOLCENGINE_TTS_API_KEY
OPC_PROVIDER_VOLCENGINE_TTS_REGION
OPC_PROVIDER_VOLCENGINE_TTS_MODEL
OPC_PROVIDER_VOLCENGINE_TTS_CREATE_PATH
OPC_PROVIDER_VOLCENGINE_TTS_QUERY_PATH
OPC_PROVIDER_VOLCENGINE_TTS_CANCEL_PATH
OPC_PROVIDER_VOLCENGINE_TTS_HEADERS_JSON
OPC_PROVIDER_VOLCENGINE_TTS_REQUEST_BODY_JSON
OPC_PROVIDER_VOLCENGINE_TTS_QUERY_BODY_JSON
OPC_PROVIDER_VOLCENGINE_TTS_AUTH_HEADER_NAME
OPC_PROVIDER_VOLCENGINE_TTS_AUTH_HEADER_PREFIX
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_TASK_ID_PATH
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_STATUS_PATH
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_PROGRESS_PATH
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_AUDIO_URL_PATH
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_AUDIO_BASE64_PATH
OPC_PROVIDER_VOLCENGINE_TTS_RESPONSE_ERROR_PATH
OPC_PROVIDER_VOLCENGINE_TTS_PROCESSING_STATUSES
OPC_PROVIDER_VOLCENGINE_TTS_SUCCESS_STATUSES
OPC_PROVIDER_VOLCENGINE_TTS_FAILURE_STATUSES
OPC_PROVIDER_VOLCENGINE_TTS_DEFAULT_VOICE_CODE
OPC_PROVIDER_VOLCENGINE_TTS_DEFAULT_LANGUAGE
OPC_PROVIDER_VOLCENGINE_TTS_DEFAULT_FORMAT
OPC_PROVIDER_VOLCENGINE_TTS_TIMEOUT_SECONDS
```

## 4. Template Variables

Both providers support these variables in configured JSON templates:

```text
{{taskNo}}
{{taskType}}
{{prompt}}
{{negativePrompt}}
{{refImageUrl}}
{{model}}
{{modelName}}
{{region}}
{{apiKey}}
{{width}}
{{height}}
{{steps}}
{{cfgScale}}
{{seed}}
{{providerTaskId}}
```

Values from `AiTaskRequest.extraParams` are also exposed as template variables.
For video this is where `durationSeconds`, `ratio`, `resolution`, `fps`, and
`seed` belong. For TTS this is where `voiceCode`, `language`, `speed`, and
`format` belong.

Example video body template:

```json
{
  "model": "{{model}}",
  "prompt": "{{prompt}}",
  "image_url": "{{refImageUrl}}",
  "duration": "{{durationSeconds}}",
  "ratio": "{{ratio}}",
  "idempotency_key": "{{taskNo}}"
}
```

The exact field names must be replaced with the names in the official
Volcengine contract before enabling the provider.

## 5. Status Mapping

The provider maps vendor status strings to the existing project states:

```text
processing -> RUNNING
success    -> SUCCESS
failure    -> FAILED
```

The comma-separated environment lists control the exact vendor strings:

```text
OPC_PROVIDER_VOLCENGINE_VIDEO_PROCESSING_STATUSES
OPC_PROVIDER_VOLCENGINE_VIDEO_SUCCESS_STATUSES
OPC_PROVIDER_VOLCENGINE_VIDEO_FAILURE_STATUSES
```

The same three lists exist for TTS.

## 6. Failure Policy

For the two real Volcengine providers:

- Missing configuration fails the task with a readable error.
- Authentication failure fails the task.
- Rate limiting fails the task and can be retried.
- Failure is never silently replaced by a Mock result.
- The existing `MockAiProvider` remains available only for explicit Mock skills.

## 7. Security and Operations

- Do not print API keys.
- Do not return API keys through `/api/**`.
- Do not put API keys in Flutter or admin-web.
- Keep provider calls in the backend.
- Record provider status and redacted error messages in task logs.
- Use the official provider's rate limits and timeout guidance.

## 8. Real Integration Acceptance

Before enabling a production key:

1. Fill every required path from the official documentation.
2. Run the local HTTP contract tests.
3. Run the full backend Maven test suite.
4. Enable the provider with a test environment.
5. Generate one image-to-video task and verify query success.
6. Generate one TTS task and verify the audio URL/bytes are playable.
7. Verify the same task cannot be submitted twice.
8. Verify provider timeout and retry behavior.