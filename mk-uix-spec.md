# MockAfka Frontend — Technical Specification

**Service name:** `bb-credit-domain_mockafka-frontend`
**Type:** Browser single-page application (Angular)
**Status of this document:** Reconstruction specification — sufficient to rebuild the
service from an empty repository without reference to the existing source.
**Derived from:** `develop` @ `7c8dd47`
**Last updated:** 2026-08-24

---

## 1. Purpose and scope

### 1.1 What this service is

MockAfka Frontend is an internal engineering tool for the Business Bank Credit
domain. It is the human interface to **`events-management-service`** (a Java/Spring
backend, out of scope here) and lets a developer or tester:

1. Browse the Avro schemas registered in the Confluent-style schema registry the
   backend fronts, including every version of each subject.
2. Generate a syntactically and semantically valid sample JSON payload for any
   schema version, including correct wire encodings for Avro logical types.
3. Validate a hand-written or generated payload against a schema version before
   sending anything to Kafka.
4. Publish a single event to a chosen Kafka topic, with optional message key,
   idempotency key and explicit schema version.
5. Bulk-publish N synthetic events generated from a schema, with configurable
   throughput delay, key strategy, event-type preset and per-field overrides.
6. Search, inspect and replay the history of everything that has been published
   through the backend.

### 1.2 What this service is not

- It has **no persistence of its own**. Every piece of durable state lives in the
  backend. Client-side state is either transient component state or two UI
  preferences in `localStorage` (theme, palette).
- It has **no authentication or authorisation layer**. It relies entirely on
  network placement (cluster-internal ingress) and whatever the ingress enforces.
  The error interceptor handles `401`/`403` by showing a message; there is no login
  flow, token store, guard or refresh logic.
- It does **not talk to Kafka or the schema registry directly**. All traffic goes
  through the backend via a single `/api/v1` prefix.
- It has **no server-side rendering**. It is a static bundle served by NGINX. The
  `isPlatformBrowser` guards in the theme and palette services are defensive only.

### 1.3 Glossary

| Term | Meaning |
|---|---|
| **Subject** | Schema-registry subject name, e.g. `avro_dto_repayments_RepaymentTransaction-value`. Owns an ordered set of integer versions. |
| **Domain** | The 3rd underscore-delimited segment of a subject (`avro_dto_<domain>_<Name>`). Used purely for grouping in the UI. |
| **Topic** | Kafka topic name. Supplied by the backend, tagged with an environment and optional category/description. |
| **Published message** | Backend record of one publish attempt (successful or failed), addressable by id and replayable. |
| **Correlation id** | Request-scoped trace id. Generated per HTTP request by an interceptor; also returned by the backend on publish. |
| **Idempotency key** | Caller-supplied key the backend uses to suppress duplicate publishes. |
| **Palette** | One of 7 brand colour sets, orthogonal to light/dark theme. |

---

## 2. System context

```
                            ┌──────────────────────────────┐
   Browser ───────────────► │ NGINX (this container)       │
                            │  :8080                       │
                            │   /            → index.html  │  SPA fallback
                            │   /api/        → proxy_pass  │──┐
                            │   /health      → 200         │  │
                            │   *.js|css|... → 1y cache    │  │
                            └──────────────────────────────┘  │
                                                              ▼
                                        ┌───────────────────────────────────┐
                                        │ events-management-service:8080    │
                                        │  Kafka producer + schema registry │
                                        │  client + published-message store │
                                        └───────────────────────────────────┘
```

- In production the browser only ever sees one origin. The API is same-origin under
  `/api/`, reverse-proxied by the same NGINX that serves the bundle. There is
  therefore **no CORS configuration anywhere in the frontend**.
- In local development the same illusion is created by the Angular dev-server
  proxy (`proxy.conf.json`), which forwards `/api` to `http://localhost:8080`.
- Deployment target is Kubernetes namespace `bb-credit-domain-<env>`, deployed by
  ArgoCD from a separate GitOps repository. The frontend's CI publishes an image
  and calls a shared deploy action; it does not own the Helm values.

---

## 3. Technology stack

Exact versions are load-bearing: Angular 21 removes `standalone: true`, ships the
`@angular/build` builders including a Vitest-based `unit-test` builder, and uses the
signal-based `input()`/`output()` API that the whole codebase assumes.

| Concern | Choice | Version |
|---|---|---|
| Framework | Angular (standalone, signals) | `^21.1.0` |
| Build | `@angular/build` application builder | `^21.1.2` |
| CLI | `@angular/cli` | `^21.1.2` |
| UI kit | Angular Material + CDK | `^21.1.3` |
| Language | TypeScript, strict | `~5.9.2` |
| Reactive | RxJS | `~7.8.0` |
| Dates | `date-fns` | `^4.1.0` |
| Tests | Vitest + jsdom via `@angular/build:unit-test` | `^4.0.8` / `^27.1.0` |
| Styling | SCSS + CSS custom properties | — |
| Runtime image | `nginx:alpine`, non-root | — |
| Node | `>=20.0.0 <21.0.0 \|\| >=22.0.0`; CI and `.nvmrc` use 22 | — |
| Package manager | npm | `11.8.0` |

No state-management library. No HTTP client wrapper beyond `HttpClient`. No
component library other than Material. No CSS framework. No linter is configured —
formatting is Prettier only, and the design-system rules are enforced by a bespoke
audit script (§13.7).

---

## 4. Repository layout

```
.
├── .claude/
│   └── skills/angular-frontend-design/   # design-system skill (rules + copyable assets)
│       ├── SKILL.md
│       ├── assets/{styles,theming,theme-boot.html,audit-design-tokens.sh}
│       └── references/{tokens,patterns,layout,material}.md
├── .github/
│   ├── dependabot.yml
│   └── workflows/{build-deploy.yaml,delete-branch.yaml}
├── public/                               # copied verbatim to the bundle root
├── scripts/
│   ├── audit-design-tokens.sh            # npm run audit:design
│   └── generate-component.sh             # component scaffolder
├── src/
│   ├── index.html                        # includes the pre-paint theme boot script
│   ├── main.ts
│   ├── styles.scss                       # ordered @use index — order is load-bearing
│   ├── styles/                           # the design system (partials, no component CSS)
│   │   ├── _material-theme.scss
│   │   ├── _tokens.scss
│   │   ├── _base.scss
│   │   ├── _material-overrides.scss
│   │   ├── _patterns.scss
│   │   ├── _a11y.scss
│   │   └── _breakpoints.scss             # not @used by styles.scss; imported per-component
│   └── app/
│       ├── app.ts, app.config.ts, app.routes.ts
│       ├── core/
│       │   ├── config/api.config.ts
│       │   ├── interceptors/{correlation-id,error}.interceptor.ts + index.ts
│       │   ├── models/*.model.ts + index.ts
│       │   └── services/*.service.ts + index.ts
│       ├── layout/{header,sidebar,main-layout}/
│       ├── features/
│       │   ├── dashboard/
│       │   ├── publish/  (+ components/{schema-selector,topic-selector,json-editor,validation-results})
│       │   ├── schemas/  (+ components/{schema-list,schema-detail,schema-version-selector})
│       │   └── messages/ (+ components/{message-filters,message-table,message-detail,replay-dialog})
│       └── shared/
│           ├── components/{json-viewer,loading-spinner,confirmation-dialog,theme-toggle,palette-selector}
│           └── pipes/{date-format,json-format}.pipe.ts
├── Dockerfile
├── nginx.conf                            # site config → /etc/nginx/conf.d/default.conf
├── nginx-main.conf                       # reference main config (see §14.3 note)
├── angular.json, tsconfig*.json, proxy.conf.json, vite.config.ts
├── AGENTS.md                             # architecture + TypeScript conventions
└── package.json
```

**Conventions that must be preserved:**

- Feature folders are self-contained: a route file, a container component, and a
  `components/` subfolder of presentational children used only by that feature.
- `core/` holds application-wide singletons and types. `shared/` holds
  presentation-only reusables. Neither imports from `features/`.
- Barrel files exist at `core/models`, `core/services`, `core/interceptors`,
  `shared/components`, `shared/pipes` and are the expected import path.
- Component files are colocated (`x.component.ts|html|scss|spec.ts`) and referenced
  with the singular `templateUrl` / `styleUrl` options using paths relative to
  the `.ts` file.

---

## 5. Build and tooling configuration

### 5.1 `angular.json`

Single project, `projectType: application`, `sourceRoot: src`, `prefix: app`,
component schematic style `scss`, CLI analytics disabled.

**build** — `@angular/build:application`
```
browser:               src/main.ts
tsConfig:              tsconfig.app.json
inlineStyleLanguage:   scss
assets:                [{ glob: "**/*", input: "public" }]
styles:                [ src/styles.scss ]
stylePreprocessorOptions.includePaths: [ src/styles ]   # enables @use 'breakpoints'
defaultConfiguration:  production
```
- `production`: `outputHashing: all`; budgets — initial 500 kB warn / 1 MB error,
  any component style 4 kB warn / 8 kB error.
- `development`: `optimization: false`, `extractLicenses: false`, `sourceMap: true`.

The `includePaths` entry is mandatory. Component stylesheets do
`@use 'breakpoints' as bp;` with no relative path and will not compile without it.

**serve** — `@angular/build:dev-server`
```
host: 0.0.0.0   port: 8080   hmr: true
allowedHosts: [ mockafka-frontend-dev.credit.npr-plbcrd.asgard.capi ]
configurations:
  development (default) → build:development
  production            → build:production
  local                 → build:development, port 4200, proxyConfig proxy.conf.json
```

**test** — `@angular/build:unit-test` with no extra options; Vitest + jsdom are
picked up from `devDependencies`, globals from `tsconfig.spec.json`.

### 5.2 TypeScript

`tsconfig.json` (base, `files: []`, project references to app and spec):
```
strict, noImplicitOverride, noPropertyAccessFromIndexSignature, noImplicitReturns,
noFallthroughCasesInSwitch, skipLibCheck, isolatedModules, experimentalDecorators,
importHelpers, target ES2022, module preserve
angularCompilerOptions: strictInjectionParameters, strictInputAccessModifiers,
                        strictTemplates, enableI18nLegacyMessageIdFormat: false
```
`noPropertyAccessFromIndexSignature` is why route/query-param and dynamic-schema
access is written `params['topic']` and `obj['type']` throughout — index access is
required, not stylistic.

- `tsconfig.app.json`: includes `src/**/*.ts`, excludes `*.spec.ts`, `types: []`.
- `tsconfig.spec.json`: includes `src/**/*.d.ts` and `src/**/*.spec.ts`,
  `types: ["vitest/globals"]`.

### 5.3 npm scripts

```
start        ng serve                              # 0.0.0.0:8080, no proxy
start:local  ng serve --configuration local        # 127.0.0.1:4200 + /api proxy
build        ng build                              # production by default
watch        ng build --watch --configuration development
test         ng test
prodrun      ng serve --host 0.0.0.0 --port 8080
audit:design bash scripts/audit-design-tokens.sh
```

### 5.4 Formatting

Prettier configured inline in `package.json`: `printWidth: 100`,
`singleQuote: true`, and an override forcing the `angular` parser for `*.html`.

### 5.5 `proxy.conf.json`

```json
{ "/api": { "target": "http://localhost:8080", "secure": false,
            "logLevel": "debug", "changeOrigin": true,
            "pathRewrite": { "^/api": "/api" } } }
```
Used only by the `local` serve configuration. The path rewrite is an identity
mapping and exists for documentation.

### 5.6 Files that are vestigial

Reproduce these only if you want byte-parity with the current repo; they have no
effect on the built application:

- `vite.config.ts` — a standalone Vite dev-server config with `wss` HMR pinned to
  the dev hostname. The Angular builder does not read it. Excluded from the image.
- `.env` — `FASTIFY_*` variables left over from the service template.
- `.devcontainer/devcontainer.json` — describes a "Fastify Node+Typescript"
  container and runs `cd source && npm install`, a directory that does not exist.
- `nginx-main.conf` — a full `nginx.conf` replacement that is **not** copied by the
  Dockerfile (see §14.3).

---

## 6. Application runtime architecture

### 6.1 Bootstrap

`src/main.ts`
```ts
bootstrapApplication(App, appConfig).catch((err) => console.error(err));
```

`src/app/app.ts` — root component `app-root`, `OnPush`, inline template
`<router-outlet />`, inline `:host { display: block; height: 100% }`.
(`app.html` and `app.scss` exist as duplicates of the inline versions and are not
referenced; a from-scratch build should keep only the inline form.)

### 6.2 Providers — `app.config.ts`

```ts
export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([correlationIdInterceptor, errorInterceptor])),
    provideAnimationsAsync(),
    { provide: API_CONFIG, useValue: DEFAULT_API_CONFIG },
  ],
};
```

Notes:
- Interceptor order matters: correlation id is applied on the way out, the error
  interceptor wraps everything inside it on the way back.
- `provideAnimationsAsync()` keeps the animations package out of the initial chunk;
  tests must therefore import `NoopAnimationsModule`.
- `withComponentInputBinding()` is enabled but currently unused — every feature
  reads query params through `ActivatedRoute` instead.
- The API config is injected through an `InjectionToken`, so a test or a future
  environment file can swap the base URL without touching services.

### 6.3 Routing

`app.routes.ts` — one shell route wrapping four lazily-loaded features:

| Path | Loads | Child routes |
|---|---|---|
| `''` | `MainLayoutComponent` (eager) | see below |
| `''` (child) | redirect → `dashboard`, `pathMatch: 'full'` | |
| `dashboard` | `features/dashboard/dashboard.routes` → `DASHBOARD_ROUTES` | `''` → `DashboardComponent`, title `Dashboard - Event Publisher` |
| `publish` | `features/publish/publish.routes` → `PUBLISH_ROUTES` | `''` → `PublishEventComponent` (`Publish Event - Event Publisher`); `bulk` → `BulkPublishComponent` (`Bulk Publish Events - Event Publisher`) |
| `schemas` | `features/schemas/schemas.routes` → `SCHEMA_ROUTES` | `''` → `SchemaBrowserComponent` (`Schema Browser - Event Publisher`) |
| `messages` | `features/messages/messages.routes` → `MESSAGE_ROUTES` | `''` → `MessageListComponent` (`Message History - Event Publisher`) |
| `**` | redirect → `dashboard` | |

Route titles are set per route via the `title` property. The wildcard redirect plus
the NGINX `try_files` fallback together guarantee deep links work.

**Cross-feature navigation contract** — features communicate exclusively through
query params:

| From | To | Query params |
|---|---|---|
| Dashboard stat / topic chip / recent message | `/messages` | `topic`, `status`, or `correlationId` |
| Dashboard schema item | `/schemas` | `subject` |
| Schema browser "Publish Event" | `/publish` | `subject` |
| Publish success "View Message" | `/messages` | `correlationId` (falls back to `messageId`) |

Receivers must tolerate an unknown value: `/publish` and `/schemas` only apply
`subject` if it exists in the loaded subject list.

### 6.4 Interceptors

**`correlationIdInterceptor`** — clones every request adding
`X-Correlation-Id: ${Date.now()}-${Math.random().toString(36).substring(2, 11)}`.

> Behavioural consequence to preserve or deliberately change: `clone({ setHeaders })`
> **overwrites** an existing header, so a caller-supplied `X-Correlation-Id` (which
> `EventService.publishEvent` supports) never reaches the backend. If caller-supplied
> correlation ids must win, the interceptor has to check `req.headers.has(...)` first.

**`errorInterceptor`** — `catchError` on every response; maps to a message and calls
`NotificationService.showError`, then re-throws:

| Condition | Message |
|---|---|
| `error.error instanceof ErrorEvent` | `Client error: ${message}` |
| 400 | `error.error?.message` ?? `Bad request` |
| 401 | `Unauthorized` |
| 403 | `Forbidden` |
| 404 | `Resource not found` |
| 422 | `error.error?.message` ?? `Validation error` |
| 500 | `Internal server error` |
| 503 | `Service unavailable` |
| other | `error.error?.message` ?? `Server error: ${status}` |
| no match at all | `An unexpected error occurred` |

Because most services also `catchError` and substitute a fallback value, a failed
call typically produces **both** a snackbar (interceptor) and an inline error state
(service). That is the intended UX: transient toast plus persistent, retryable
inline banner.

### 6.5 Change detection and state

- Every component except `BulkPublishComponent` declares
  `changeDetection: ChangeDetectionStrategy.OnPush`.
- State is held in `signal()`s, exposed as `asReadonly()`, derived with `computed()`.
  `update`/`set` only — never `mutate`.
- Services own the state for anything shared (loading flags, last result, error
  string); components own view-local state.
- **The codebase does not use the `async` pipe.** Components subscribe in
  TypeScript and push into signals; templates read signals only. `AGENTS.md` records
  this as a known, deliberate deviation from the Angular style guide — match the
  surrounding code rather than the guide.
- Subscriptions are generally not unsubscribed. This is safe for the single-shot
  `HttpClient` observables that dominate, but `route.queryParams` and
  `BreakpointObserver.observe` subscriptions do leak for the component's lifetime.
  A from-scratch build should use `takeUntilDestroyed()` for those two.

---

## 7. Domain model

All types live in `src/app/core/models/`, exported through `index.ts` in this order:
`publish-request`, `publish-response`, `bulk-publish`, `validation-response`,
`schema`, `published-message`, `page`, `message-search`, `replay-request`, `theme`,
`palette`, `topic`.

These mirror the backend DTOs. Field optionality is exactly as the backend emits it.

### 7.1 Publishing

```ts
export interface PublishRequest {
  payload: unknown;                        // parsed JSON, sent as the request body
  key?: string;                            // Kafka message key
  headers?: Record<string, string>;
  schemaVersion?: number;
}

export interface PublishParams {           // becomes query params + headers
  schemaSubject: string;
  topic: string;
  correlationId?: string;
  idempotencyKey?: string;
}

export type PublishStatus = 'SUCCESS' | 'FAILED';

export interface PublishResponse {
  status: PublishStatus;
  topic: string;
  partition?: number;
  offset?: number;
  timestamp?: string;
  messageId?: string;
  correlationId?: string;
  errorMessage?: string;
  errorCode?: string;
}
```

### 7.2 Bulk publishing

```ts
export interface BulkPublishRequest {
  schemaSubject: string;
  schemaVersion?: number;
  topic: string;
  numberOfMessages: number;                // 1..10000, enforced client-side
  delayBetweenMessagesMs?: number;         // 0..10000
  randomKeys: boolean;
  fixedKey?: string;                       // only meaningful when randomKeys === false
  eventType?: string;                      // backend preset selector
  fieldOverrides?: Record<string, any>;    // dot-notation path → value
}

export interface BulkPublishResponse {
  status: 'SUCCESS' | 'PARTIAL_SUCCESS' | 'FAILED';
  topic: string;
  totalMessages: number;
  successCount: number;
  failureCount: number;
  durationMs: number;
  startedAt: string;                       // ISO-8601
  completedAt: string;
  results?: BulkPublishResult[];
  errorMessage?: string;
}

export interface BulkPublishResult {
  messageIndex: number;                    // 0-based; displayed +1
  status: 'SUCCESS' | 'FAILED';
  partition?: number;
  offset?: number;
  errorMessage?: string;
  key?: string;
}

export interface BulkPublishProgress {     // declared for incremental progress;
  totalMessages: number;                   // not currently produced by anything —
  processedMessages: number;               // the endpoint is a single blocking call
  successCount: number;
  failureCount: number;
  isComplete: boolean;
  currentMessage?: number;
}
```

### 7.3 Validation

```ts
export interface ValidationError {
  field?: string;
  path?: string;                           // preferred display key
  message: string;
  expectedType?: string;
  actualValue?: string;
}

export interface ValidationResponse {
  valid: boolean;
  errors: ValidationError[];               // always an array; empty when valid
  schemaSubject?: string;
  schemaVersion?: number;
}
```

### 7.4 Schemas

```ts
export interface SchemaResponse {
  id?: number | null;
  name: string;
  subject: string;
  version: number;
  schemaId?: number | null;
  avroSchema: ParsedAvroSchema;            // parsed tree, used by the UI
  avroSchemaJson: string;                  // raw text, used for copy-to-clipboard
  fingerprint?: string;
  createdAt?: string | null;
}

export interface SchemaSubject {           // assembled client-side, not a backend DTO
  subject: string;
  latestVersion: number;                   // max(versions), 0 when unknown
  versions: number[];
}

export interface ParsedAvroSchema {
  type: string; name: string; namespace?: string;
  version?: string; doc?: string; fields?: AvroField[];
}

export interface AvroField { name: string; type: AvroFieldType; doc?: string; default?: unknown; }

export type AvroFieldType =
  | string                                                   // "string", "long", …
  | string[]                                                 // union, e.g. ["null","string"]
  | { type: string; items?: AvroFieldType;                   // array
      values?: AvroFieldType; symbols?: string[] };          // map / enum
```
`AvroFieldType` deliberately under-describes reality (it omits `logicalType`,
`precision`, `scale`, `size`, nested `fields`). The template generator therefore
works on `Record<string, unknown>` and index access rather than this type. Keep both:
the narrow type documents the common case, the wide access handles the rest.

### 7.5 Published messages, paging, search, replay

```ts
export type MessageStatus = 'SUCCESS' | 'FAILED';

export interface PublishedMessage {
  id: string; topic: string; key?: string;
  payload?: unknown; headers?: Record<string, string>;
  status: MessageStatus; partition?: number; offset?: number;
  schemaSubject?: string; schemaVersion?: number;
  correlationId?: string; idempotencyKey?: string;
  errorMessage?: string; errorCode?: string;
  createdAt: string; publishedAt?: string;
}

export interface Page<T> {                 // Spring Data page shape
  content: T[]; totalElements: number; totalPages: number;
  number: number; size: number;
  first: boolean; last: boolean; empty: boolean;
}

export interface PageRequest { page: number; size: number; sort?: string; direction?: 'asc' | 'desc'; }

export interface MessageSearchParams {
  topic?: string; schemaSubject?: string; status?: MessageStatus;
  correlationId?: string; idempotencyKey?: string; messageKey?: string;
  startDate?: string;                      // ISO-8601, inclusive start of day
  endDate?: string;                        // ISO-8601, inclusive end of day
  page?: number; size?: number;
}

export interface ReplayRequest  { useLatestSchema?: boolean; schemaVersionOverride?: number; }
export interface ReplayResponse { success: boolean; newMessageId?: string; errorMessage?: string; }
```
`PageRequest` and `ReplayResponse` are declared but unused — replay actually returns
`PublishResponse`. A clean build should either wire `ReplayResponse` in or drop it.
`MessageSearchParams.idempotencyKey` and `messageKey` are sent by the service but
have no filter control in the UI; they are reachable only via a hand-built URL.

### 7.6 Topics

```ts
export interface TopicsListResponse {
  categories: string[]; environments: string[];
  topics: TopicInfo[]; totalCount?: number;
}
export interface TopicInfo {
  id?: string; name: string; category?: string;
  environment?: string; description?: string;
}
```
`categories` and `totalCount` are received and discarded by the current UI.

### 7.7 UI preference models

```ts
export enum ThemeMode { LIGHT = 'light', DARK = 'dark', SYSTEM = 'system' }
export type EffectiveTheme = 'light' | 'dark';

export enum Palette { BLUE='blue', GREEN='green', TEAL='teal', PURPLE='purple',
                      PINK='pink', GOLD='gold', RED='red' }
export interface PaletteInfo { id: Palette; name: string; color: string; }

export const PALETTES: PaletteInfo[] = [
  { id: Palette.BLUE,   name: 'Blue',   color: '#3b82f6' },
  { id: Palette.GREEN,  name: 'Green',  color: '#22c55e' },
  { id: Palette.TEAL,   name: 'Teal',   color: '#14b8a6' },
  { id: Palette.PURPLE, name: 'Purple', color: '#a855f7' },
  { id: Palette.PINK,   name: 'Pink',   color: '#ec4899' },
  { id: Palette.GOLD,   name: 'Gold',   color: '#eab308' },
  { id: Palette.RED,    name: 'Red',    color: '#ef4444' },
];
```
`PaletteInfo.color` is the swatch shown in the picker and is the only place a hex
literal legitimately appears in TypeScript. It must stay in sync with `--primary`
for that palette in `_tokens.scss`.

---

## 8. Backend API contract

### 8.1 Configuration

```ts
export interface ApiConfig {
  baseUrl: string;
  endpoints: { schemas: string; events: string; messages: string; topics: string };
}
export const API_CONFIG = new InjectionToken<ApiConfig>('API_CONFIG');
export const DEFAULT_API_CONFIG: ApiConfig = {
  baseUrl: '/api/v1',
  endpoints: { schemas: '/schemas', events: '/events',
               messages: '/published-messages', topics: '/topics' },
};
```
All URLs are relative — same-origin by construction. Every request additionally
carries `X-Correlation-Id` from the interceptor.

### 8.2 Endpoints

| # | Method | Path | Query | Body | Response |
|---|---|---|---|---|---|
| 1 | GET | `/api/v1/schemas/subjects` | — | — | `string[]` |
| 2 | GET | `/api/v1/schemas/{subject}/versions` | — | — | `number[]` |
| 3 | GET | `/api/v1/schemas/{subject}/versions/{version}` | — | — | `SchemaResponse` |
| 4 | GET | `/api/v1/schemas/{subject}/versions/latest` | — | — | `SchemaResponse` |
| 5 | GET | `/api/v1/topics` | — | — | `TopicsListResponse` |
| 6 | POST | `/api/v1/events/validate` | `schemaSubject` (req), `schemaVersion` (opt) | **raw payload JSON string**, `Content-Type: application/json` | `ValidationResponse` |
| 7 | POST | `/api/v1/events/publish` | `schemaSubject`, `topic` | `PublishRequest` | `PublishResponse` |
| 8 | POST | `/api/v1/events/bulk-publish` | — | `BulkPublishRequest` | `BulkPublishResponse` |
| 9 | GET | `/api/v1/published-messages` | see §7.5 `MessageSearchParams` | — | `Page<PublishedMessage>` |
| 10 | GET | `/api/v1/published-messages/{id}` | — | — | `PublishedMessage` |
| 11 | POST | `/api/v1/published-messages/{id}/replay` | — | `ReplayRequest` | `PublishResponse` |

Endpoint-specific notes that must be reproduced exactly:

- **#6 `validate`** sends the payload as the *unparsed editor text*, not a wrapped
  object. The service is handed a string and posts it verbatim with an explicit
  `Content-Type: application/json` header. Sending `{ payload: … }` here will fail.
- **#7 `publish`** takes the subject and topic as *query params* and everything else
  in the body. Optional `X-Correlation-Id` and `Idempotency-Key` headers are set from
  `PublishParams` (but see the interceptor caveat in §6.4).
- **#9 `published-messages`** query params are omitted entirely when falsy. `page`
  and `size` are only sent when `!== undefined`, so `page=0` is sent correctly.
- **#3 vs #4**: `SchemaService.getSchema(subject, version)` chooses `latest` when
  `version` is falsy. Because the check is truthiness, **version `0` resolves to
  `latest`**. Registry versions start at 1, so this is currently harmless.

### 8.3 Error shape

The frontend assumes errors may carry `{ message: string }` in the body
(`error.error?.message`) and otherwise relies on the status code. No other error
envelope is parsed.

---

## 9. Core services

All are `@Injectable({ providedIn: 'root' })` and use `inject()`, never constructor
parameters (`MainLayoutComponent` is the one legacy exception). Each service owns a
single responsibility and exposes read-only signals plus observable-returning
methods. Callers subscribe for sequencing; they read state from the signals.

### 9.1 `SchemaService`

State: `subjects: Signal<SchemaSubject[]>`, `loading: Signal<boolean>`,
`error: Signal<string | null>`.

| Method | Behaviour |
|---|---|
| `loadSubjects(): Observable<SchemaSubject[]>` | Sets `loading`, clears `error`. GETs #1. If empty → `of([])`. Otherwise fan-out: one #2 per subject via `forkJoin`, each mapped to `{ subject, versions, latestVersion: max(versions) \|\| 0 }` and individually `catchError`-ed to `{ subject, versions: [], latestVersion: 0 }`. On success pushes into `subjects`, clears `loading`. On outer failure clears `loading`, sets `error` to `'Failed to load schemas. Please check if the API server is running.'`, returns `of([])`. |
| `getSchema(subject, version?)` | #3 or #4 depending on `version`; `catchError → of(null)`. |
| `getSchemaVersions(subject)` | #2; `catchError → of([])`. |
| `getLatestSchema(subject)` | #4; `catchError → of(null)`. |

> **Scaling characteristic to be aware of:** `loadSubjects` issues *1 + N* requests
> for N subjects, in parallel, and is called on entry to Dashboard, Publish, Bulk
> Publish and Schema Browser. Loaded subjects are cached in the signal, and
> `SchemaSelectorComponent` skips the call when the list is already populated, but
> the container components call it unconditionally on every `ngOnInit`. If the
> backend ever exposes a combined subjects+versions endpoint, this is the first
> thing to move to it.

### 9.2 `TopicService`

State: `topics`, `environments`, `loading`, `error`.
`loadTopics()` GETs #5, pushes `response.topics` and `response.environments`, clears
`loading`. On failure sets `error` to
`'Failed to load topics. Please check if the API server is running.'` and returns
`of({ categories: [], environments: [], topics: [] })`.

### 9.3 `EventService`

State: three independent booleans — `publishing`, `validating`, `bulkPublishing`.

| Method | Behaviour |
|---|---|
| `validateEvent(schemaSubject, payloadJson, schemaVersion?)` | Sets `validating`. POST #6. `tap` clears the flag. On error clears the flag and returns a synthetic `{ valid: false, errors: [{ message: err.error?.message ?? 'Validation failed' }] }` so the UI always has a result to render. |
| `publishEvent(publishParams, request)` | Sets `publishing`. POST #7 with query params and optional headers. On error returns a synthetic `{ status: 'FAILED', topic, errorMessage }`. |
| `bulkPublishEvents(request)` | Sets `bulkPublishing`. POST #8. On error returns a fully populated failure response (`totalMessages = request.numberOfMessages`, `successCount: 0`, `failureCount: numberOfMessages`, `durationMs: 0`, `startedAt`/`completedAt` = now). |

Every method converts failure into a value on the success channel, so subscribers
only implement `next`. The loading flags are cleared in `tap`, not `finalize`, which
means an unsubscribed-before-completion call would leave a flag stuck; use
`finalize` if you rebuild this.

### 9.4 `PublishedMessageService`

State: `messages: Signal<Page<PublishedMessage> | null>`, `loading`, `error`,
`searchParams` (defaults `{ page: 0, size: 20 }`).
Derived: `messageList`, `totalElements`, `totalPages`, `currentPage`.

| Method | Behaviour |
|---|---|
| `searchMessages(params)` | Sets `loading`, clears `error`, stores `params`. Builds `HttpParams`, omitting falsy values and `undefined` page/size. GET #9. On failure sets `error` to `'Failed to load messages. Please check if the API server is running.'` and substitutes a canonical empty page (`size: 20`, `first`/`last`/`empty` true). |
| `getMessage(id)` | #10; `catchError → of(null)`. Currently unused — the detail dialog is fed the row object it already has. |
| `replayMessage(id, request)` | #11; on error returns `{ status: 'FAILED', topic: '', errorMessage }`. |
| `updateSearchParams(partial)` | Merges into the `searchParams` signal. Currently unused; `MessageListComponent` keeps its own copy. |

A `MessageStats` interface is exported from this file and used nowhere — the
dashboard computes its counters locally. Drop it or implement a stats endpoint.

### 9.5 `NotificationService`

Thin wrapper over `MatSnackBar`. `showSuccess` / `showError` / `showInfo` /
`showWarning`, each `(message, duration = 5000)`. All open with action label
`'Close'`, `horizontalPosition: 'end'`, `verticalPosition: 'top'` and
`panelClass: ['snackbar-<type>']` — the four panel classes are styled globally in
`_patterns.scss`.

### 9.6 `ThemeService`

Owns the light/dark/system tri-state.

- Storage key `theme-mode`; DOM attribute `data-theme` on `<html>`; default
  `ThemeMode.SYSTEM`.
- Internals: a `BehaviorSubject<ThemeMode>` as the write channel plus a mirrored
  `signal` for templates; a `matchMedia('(prefers-color-scheme: dark)')` listener.
- Public surface: `themeMode` (signal), `isDark` (computed), `setTheme(mode)`,
  `getTheme(): Observable`, `getCurrentTheme()`, `getEffectiveTheme(): 'light' | 'dark'`,
  `toggleTheme()` cycling light → dark → system → light.
- `applyThemeToDOM()` sets `data-theme` to the *effective* theme and rewrites the
  `<meta name="color-scheme">` content, creating the tag if absent.
- Every method early-returns when `isPlatformBrowser` is false.
- The media-query listener uses `addEventListener` with an `addListener` fallback.

> Defect to fix in a rebuild: the class declares `ngOnDestroy()` to tear the media
> listener down but does not `implement OnDestroy`, and as a root singleton it is
> never destroyed anyway. Either drop the method or use `DestroyRef`.

### 9.7 `PaletteService`

Same shape, simpler. Storage key `palette`; attribute `data-palette`; default
`Palette.BLUE`; validates the stored string against `Object.values(Palette)` before
accepting it. Exposes `palette` (signal), `palettes` (the `PALETTES` constant),
`setPalette`, `getPalette()`, `getCurrentPalette()`, `getPaletteInfo(id)`.

---

## 10. Features

### 10.1 Layout shell

**`MainLayoutComponent`** — `app-main-layout`, template:
```
<a class="skip-link" href="#main-content">Skip to main content</a>
<app-header (menuToggled)="toggleSidenav()" />
<mat-sidenav-container class="sidenav-container">
  <mat-sidenav #sidenav [mode]="isMobile() ? 'over' : 'side'" [opened]="!isMobile()"
               [fixedInViewport]="true" [fixedTopGap]="64" role="navigation">
    <app-sidebar />
  </mat-sidenav>
  <mat-sidenav-content>
    <main id="main-content" class="main-content" role="main" tabindex="-1">
      <router-outlet />
    </main>
  </mat-sidenav-content>
</mat-sidenav-container>
```
- `BreakpointObserver.observe([Breakpoints.Handset])` drives an `isMobile` signal:
  `over` + closed on handset, `side` + open otherwise. This is the sanctioned way to
  make a *behavioural* responsive change (CSS breakpoints are for layout only).
- `@ViewChild('sidenav')` + `toggleSidenav()`. This is the one component still using
  constructor injection and `@ViewChild`; a rebuild should use `viewChild()` and
  `inject()`.
- Layout metrics: header 64px fixed, sidenav 250px, main padding 24px (16px below
  the 600px breakpoint), `min-height: calc(100vh - 64px - 48px)`.

**`HeaderComponent`** — `mat-toolbar color="primary"`: menu icon-button
(`aria-label="Toggle navigation menu"`) emitting `menuToggled = output<void>()`, the
brand block `Mockafka - Event Publisher`, a spacer, then `<app-palette-selector />`
and `<app-theme-toggle />`.

**`SidebarComponent`** — `mat-nav-list` over a static `NavItem[]`:

| Path | Label | Icon |
|---|---|---|
| `/dashboard` | Dashboard | `dashboard` |
| `/publish` | Publish Event | `send` |
| `/publish/bulk` | Bulk Publish | `burst_mode` |
| `/schemas` | Schema Browser | `schema` |
| `/messages` | Message History | `history` |

Each item uses `routerLink`, `routerLinkActive="active"` and
`[attr.aria-current]="isActive(path) ? 'page' : null"` — never `false`, always `null`
when inactive.

> Two defects to fix rather than reproduce: `isActive()` reads
> `window.location.pathname` directly, which is both non-reactive (it is only
> re-evaluated when something else triggers change detection) and forbidden by
> `AGENTS.md`'s "do not assume globals" rule. Use `RouterLinkActive`'s own state or
> inject `Router` and read `router.url`. Separately, `sidebar.component.spec.ts`
> asserts `navItems.length === 4` while the array has 5 entries — the test is stale
> and currently failing.

### 10.2 Dashboard (`/dashboard`)

Read-only landing page. It is a launcher, not an analytics view: all figures are
derived from the 10 most recent messages, not from an aggregate endpoint.

On init: `searchMessages({ page: 0, size: 10 })` and `loadSubjects()` in parallel.

State: `recentMessages` (signal), `loadingRecent`, `apiError`.
Computed:
- `totalMessages` → `messageService.totalElements()` (the true backend total).
- `successCount` / `failedCount` → counts **within the fetched 10**.
- `topTopics` → topic frequency over the fetched 10, sorted desc, top 5.

`apiError` is set when the message page comes back empty *and* `schemaService.error()`
is set — i.e. only when both calls appear to have failed. Rendered as
`.error-banner .error-banner--warning` with `role="alert"`, a `cloud_off` icon and a
Retry button that clears the flag and reloads both.

Layout:
- Header: `<h1>Dashboard</h1>` + a primary "Publish Event" button.
- `.stats-row`: four clickable `.stat-item` tiles — Messages → `/messages`,
  Successful → `/messages?status=SUCCESS`, Failed → `/messages?status=FAILED`,
  Schemas → `/schemas`.
- `.content-grid`: two cards.
  - *Recent Activity* — loading spinner (24px) → up to 3 topic chips (only when
    `topTopics().length > 1`) plus the 5 newest messages, each a `.status-badge`
    (`--success`/`--error`) + topic + `createdAt | dateFormat:'MMM d, HH:mm'`, whole
    row navigating to `/messages?correlationId=…`; → empty state with a
    "Publish Event" button.
  - *Schemas* — loading spinner → up to 4 subjects with `description` icon, name and
    `v{latestVersion}`, each navigating to `/schemas?subject=…`; → "No schemas
    available" empty state.

Accessibility gap to close in a rebuild: the stat tiles, message rows and schema rows
are `<div>`s with `(click)` handlers — not keyboard reachable and not announced as
controls. They should be `<button type="button">` (or carry `role="button"`,
`tabindex="0"` and a keydown handler).

### 10.3 Publish a single event (`/publish`)

The most complex screen. A four-step, progressively-revealed form.

On init: `loadTopics()`, then `loadSubjects()`; inside the subjects callback it
subscribes to `queryParams` and auto-selects `?subject=` **only if that subject
exists** in the loaded list.

State signals: `selectedSubject`, `selectedVersion`, `selectedEnvironment`,
`selectedTopic`, `useCustomTopic`, `jsonPayload`, `isJsonValid`, `selectedSchema`,
`validationResult`, `publishResult`. Two reactive controls (`keyControl`,
`idempotencyKeyControl`).

Derived:
```
schemaTemplate  = generateTemplate(selectedSchema().avroSchema)      // see §11
hasPayload      = !!jsonPayload().trim()
canValidate     = selectedSubject && hasPayload && isJsonValid
canPublish      = canValidate && selectedTopic
validateTooltip / publishTooltip = the unmet requirements joined with ' • '
```

**Invalidation rule:** changing the subject, version, environment, topic or payload
clears both `validationResult` and `publishResult`. Changing the subject also resets
the version to `null` (latest) and reloads the schema. A result on screen always
corresponds to exactly the inputs currently on screen.

Sections:

1. **Select Schema** — `<app-schema-selector>` when subjects exist; a retryable
   `.error-banner` when `schemaService.error()`; else
   "No schemas available. Please add schemas to the registry first."
2. **Specify Topic** (only after a subject is chosen) — a "Custom Topic" /
   "Use Topic List" toggle button (hidden while topics are loading or errored),
   an indeterminate progress bar while loading, a retryable banner on error, else
   `<app-topic-selector>`.
3. **Enter Payload** — a "Use Template" button (only when a schema is loaded) that
   sets `jsonPayload` to `schemaTemplate()` and force-sets `isJsonValid` to true,
   plus `<app-json-editor>`.
4. **Advanced Options** — a collapsed `mat-expansion-panel` with Message Key
   (hint: "Used for partitioning in Kafka") and Idempotency Key (hint: "Prevents
   duplicate publishes").
5. **Actions** — an indeterminate progress bar while validating or publishing; a
   live requirements checklist (`role="status"`, `aria-live="polite"`) rendered only
   while `!canPublish()`, each item showing `check_circle` or
   `radio_button_unchecked`; then Validate (stroked) and Publish Event (flat,
   primary). Disabled buttons are wrapped in a `.button-wrapper` div carrying the
   tooltip, because a disabled Material button does not fire the events
   `matTooltip` needs.
6. **Results** — `<app-validation-results>` when a validation result exists; a
   result card for the publish outcome showing Topic, Partition, Offset, Message ID,
   Correlation ID and Error as available, plus a "View Message" button on success
   that navigates to `/messages?correlationId=…`.

`publish()` re-parses the payload inside a `try/catch` and shows
`'Invalid JSON payload'` on failure. Success and failure both raise a snackbar.

### 10.4 Bulk publish (`/publish/bulk`)

A single reactive `FormGroup`:

| Control | Default | Validators |
|---|---|---|
| `schemaSubject` | `''` | required |
| `schemaVersion` | `null` | — |
| `topic` | `''` | required |
| `numberOfMessages` | `10` | required, min 1, max 10000 |
| `delayBetweenMessagesMs` | `0` | min 0, max 10000 |
| `randomKeys` | `true` | — |
| `fixedKey` | `''` | — (enable/disable driven by `randomKeys`) |
| `eventType` | `''` | — |
| `fieldOverrides` | `''` | parsed as JSON on submit |

- On init: `loadSubjects()`, `loadTopics()`, and a `randomKeys` `valueChanges`
  subscription that disables and clears `fixedKey` when random keys are on and
  re-enables it when off. Because the control can be disabled, submit reads
  `getRawValue()`, not `value`.
- `eventType` options are hardcoded and domain-specific:
  `''` → "None (Use default schema values)",
  `RepaymentTransactionTransferCompleted` → "Successful Transaction",
  `RepaymentTransactionTransferFailed` → "Failed Transaction".
  These belong in configuration or should come from the backend; treat the list as
  data, not structure.
- `fieldOverrides` is a free-text JSON object whose keys are dot-notation paths
  (`header.tenantId`, `body.repaymentAmount`). Invalid JSON aborts submit with
  `'Invalid JSON format for field overrides'`. `addFieldOverrideExample()` inserts a
  five-key sample.
- Submit maps the form to `BulkPublishRequest`, sending `fixedKey: undefined` when
  `randomKeys` is true and coercing empty `eventType` to `undefined`. Outcome
  notifications: `SUCCESS` → success toast with counts and duration;
  `PARTIAL_SUCCESS` → warning toast; `FAILED` → error toast.
- Results card: five stat tiles (Total, Successful, Failed, Duration ms, Topic) and,
  when `results` is present, a `mat-table` with columns
  `messageIndex` (displayed +1), `status` (chip), `partition`, `offset`, `key`,
  `error` (truncated to 50 chars with the full text in a tooltip).
- `resetForm()` restores the defaults and clears every selection signal and result.

> This component is the codebase's known outlier and should be brought in line when
> rebuilt: it declares the redundant `standalone: true`, omits
> `ChangeDetectionStrategy.OnPush`, imports `CommonModule` for the `slice` pipe,
> exposes public mutable signals, and uses `Record<string, any>`. It is also the
> page that originally shipped with hardcoded colours and consequently ignored dark
> mode and every palette — the cautionary tale that motivated `npm run audit:design`.

### 10.5 Schema browser (`/schemas`)

Two-column shell: a subject list rail and a detail pane.

On init: `loadSubjects()`, then `queryParams` → auto-select `?subject=` if present in
the list. Selecting a subject clears the version and schema, fetches
`getSchemaVersions(subject)`, and auto-selects `max(versions)`. Selecting a version
fetches that exact schema.

**`SchemaListComponent`** — search + domain grouping.
- Free-text filter over `subject`, case-insensitive substring, with a clear button.
- `extractDomain(subject)`: match `/^avro_dto_([a-z]+)_/i` → group 1 lowercased;
  fallback to `parts[2]` when the subject splits on `_` into ≥3 parts starting
  `avro`,`dto`; else `'other'`.
- `getSchemaDisplayName(subject)`: match
  `/^avro_dto_[a-z]+_([A-Za-z0-9]+)(-value|-key)?$/i` → group 1; else the whole
  subject.
- Groups are sorted by display name; schemas within a group sorted by subject.
  Display name is the domain capitalised. Each group gets an icon from a
  domain→Material-icon map (`arrears: schedule`, `customer: person_outline`,
  `payments: payments`, `repayments: request_quote`, … `other: folder_open`,
  default `description`). The map is presentation data — extend freely.
- Expansion state is a `Set<string>` in a signal, replaced (never mutated) on
  toggle, with expand-all / collapse-all helpers.

**`SchemaVersionSelectorComponent`** — a select over versions sorted descending;
`versions` input, `selectedVersion` input, `versionSelected` output. Rendered by the
browser only when more than one version exists.

**`SchemaDetailComponent`** — takes a required `schema` input. Renders the field
table using `getFieldType()`, which renders a union as `a | b`, an array as
`array<T>`, a map as `map<T>`, an enum as `enum(A, B)`, and otherwise the raw
`type` string. Also offers copy-to-clipboard of `avroSchemaJson` via
`navigator.clipboard`, with a `copied` signal reset after 2s and a success snackbar,
and embeds `<app-json-viewer>` for the full schema.

The detail pane header carries the subject, the version selector and a
"Publish Event" button that routes to `/publish?subject=…`. When nothing is
selected it shows one of three placeholder messages depending on whether subjects
loaded, errored, or came back empty.

### 10.6 Message history (`/messages`)

On init it subscribes to `queryParams` and builds the initial filter from `topic`,
`correlationId`, `schemaSubject` and `status`, always resetting to
`{ page: 0, size: 20 }`, then searches. Each query-param change re-searches.

`MessageListComponent` keeps `currentSearchParams` as a plain field: a new search
resets `page` to 0 while preserving `size`; a paginator event overwrites `page` and
`size` while preserving the filters.

**`MessageFiltersComponent`** — reactive form: `topic`, `schemaSubject`, `status`
(`null` | `SUCCESS` | `FAILED`), `correlationId`, `startDate`, `endDate`
(`MatDatepicker`). An `effect()` patches the form whenever `initialParams` changes,
so a query-param-driven filter is visible in the controls. On submit, empty fields
are omitted; `startDate` is normalised to 00:00:00.000 and `endDate` to
23:59:59.999 local time before `toISOString()`, making a single-day range inclusive.
Reset clears the form and emits `{}`.

**`MessageTableComponent`** — `mat-table` with columns
`status | topic | schemaSubject | createdAt | actions`; `aria-label="Published messages"`.
Status is a `.status-badge` plus the text with `.success-text` / `.error-text`.
Schema shows `subject` and a `v{n}` suffix, or `-`. `createdAt` runs through
`dateFormat`. Actions are two icon-buttons (`visibility`, `replay`), both labelled
and tooltipped. A `*matNoDataRow` renders "No messages found". A `mat-paginator`
bound to `length/pageSize/pageIndex` from the `Page`, options `[10, 20, 50, 100]`,
`showFirstLastButtons`, labelled "Select page of messages".

Because the table is driven by `[dataSource]="messages().content"` (a plain array)
and paging is server-side, the paginator must be fed the page metadata rather than
letting `MatTableDataSource` slice locally.

**`MessageDetailComponent`** (dialog, 1000px, `maxWidth: 95vw`, `maxHeight: 90vh`) —
a definition list of Status, Topic, Key, Schema + version, Partition, Offset,
Correlation ID, Created At, Published At and Error (each conditional except Status,
Topic and Created At), then a `mat-tab-group` with a Payload tab and a Headers tab
(the latter only when `headers` has keys), each rendering `<app-json-viewer>`.
Actions: Close, and Replay which closes with `{ replay: true }` — the list then opens
the replay dialog for the same message.

**`ReplayDialogComponent`** (500px) — a `useLatestSchema` checkbox and, when it is
off, an optional numeric `schemaVersionOverride`. Sends
`{ useLatestSchema, schemaVersionOverride? }`, shows an indeterminate bar while in
flight, notifies on success and closes with `true` (which triggers a reload of the
list) or reports the error and stays open.

---

## 11. Avro sample-payload generation

This is the highest-value logic in the application and the part most likely to be
lost in a rewrite. It currently lives as private methods on
`PublishEventComponent`; a from-scratch build should extract it into a pure,
independently testable module (e.g. `core/avro/template-generator.ts`) — nothing in
it depends on Angular.

### 11.1 Contract

`generateTemplate(schema: Record<string, unknown>): string`

- If `schema['type'] !== 'record'` or `schema['fields']` is not an array, return
  `'{}'` (2-space pretty-printed).
- Otherwise, for each field: use `field.default` when it is not `undefined`,
  otherwise `generateSampleValue(field.type, field.name)`.
- Return `JSON.stringify(template, null, 2)`.

### 11.2 `generateSampleValue(type, fieldName)`

Dispatch by the shape of `type`:

| Shape | Behaviour |
|---|---|
| `string` | `getSampleForPrimitiveType(type, fieldName)` |
| `string[]` (union) | first member `!== 'null'`, recursed; `null` if the union is only `null`. **Optional fields therefore get a real value, not `null`** — intentional, so generated templates exercise the field. |
| object with `logicalType` | `getSampleForLogicalType(logicalType, fieldName, typeObj)` — checked **before** `type`, so a logical type always wins over its underlying primitive |
| object `type: 'array'` | `[ generateSampleValue(items, fieldName) ]` — exactly one element |
| object `type: 'map'` | `{ sampleKey: generateSampleValue(values, fieldName) }` |
| object `type: 'enum'` | `symbols[0]`, else `'UNKNOWN'` |
| object `type: 'record'` | recurse over nested `fields` with the same default-first rule; `{}` when `fields` is missing |
| object `type: 'fixed'` | `encodeFixedAsBase64(size ?? 16)` |
| object, other | if `type` is a string, treat as primitive; else `null` |
| anything else | `null` |

### 11.3 Primitives — field-name-aware sample values

`getSampleForPrimitiveType` lowercases the field name and branches:

- `string` → `getSampleStringValue`, first match wins, in this order:
  `id|uuid|guid` → `550e8400-e29b-41d4-a716-446655440000`; `email` →
  `user@example.com`; `phone|mobile|cell` → `+27123456789`;
  `name`+`first` → `John`; `name`+`last` → `Doe`; `name` → `Sample Name`;
  `date|time|timestamp` → `new Date().toISOString()`; `url|link` →
  `https://example.com`; `description|desc` → `Sample description text`;
  `address` → `123 Sample Street, City`; `country` → `ZA`; `currency` → `ZAR`;
  `status` → `ACTIVE`; `type` → `DEFAULT`; `code` → `CODE001`;
  `reference|ref` → `REF-12345`; `correlation` →
  `corr-550e8400-e29b-41d4-a716-446655440000`; `topic` → `sample.topic.name`;
  `key` → `sample-key`; default `sample_value`.
  *Order is load-bearing* — `reference` would otherwise be caught by nothing, and
  `id` deliberately precedes everything so `accountId` gets a UUID.
- `int` → `age`:25, `count|quantity|qty`:1, `version`:1, `port`:8080,
  `year`:current year, `month`:current month+1, `day`:current date, else `0`.
- `long` → `timestamp|time`: `Date.now()`, `amount|balance|total`: `10000`, else `0`.
- `float`/`double` → `amount|price|balance`: `100.00`, `rate|percentage|percent`:
  `0.15`, `lat|latitude`: `-26.2041`, `lon|longitude|lng`: `28.0473`, else `0.0`.
  (The lat/long defaults are Johannesburg.)
- `boolean` → `true`; `bytes` → `'c2FtcGxlIGRhdGE='` (`"sample data"`);
  `null` → `null`; unknown → `null`.

### 11.4 Logical types

| `logicalType` | Generated value |
|---|---|
| `uuid` | `550e8400-e29b-41d4-a716-446655440000` |
| `date` | `Math.floor(Date.now() / 86400000)` — epoch **days** |
| `time-millis` | `43200000` (12:00) |
| `time-micros` | `43200000000` |
| `timestamp-millis` | `Date.now()` |
| `timestamp-micros` | `Date.now() * 1000` |
| `local-timestamp-millis` | `Date.now()` |
| `local-timestamp-micros` | `Date.now() * 1000` |
| `decimal` | `encodeDecimalAsBase64(sampleDecimal(fieldName), precision ?? 19, scale ?? 2)` |
| `duration` | `encodeDurationAsBase64(0, 1, 0)` |
| anything else | `null` |

### 11.5 Binary encoders — why they exist

The backend validates against the Avro schema and rejects a plain number where
`bytes` is expected. Three encoders produce JSON-safe Base64 for the byte-backed
types. This was a real production bug fix; the tests below are regression tests, not
decoration.

```ts
// Avro decimal: unscaled big-endian two's-complement integer, here fixed at 8 bytes.
encodeDecimalAsBase64(value, precision = 19, scale = 2): string {
  const unscaled = Math.round(value * Math.pow(10, scale));
  const buffer = new ArrayBuffer(8);
  new DataView(buffer).setBigInt64(0, BigInt(unscaled), false);   // false = big-endian
  return btoa(String.fromCharCode(...new Uint8Array(buffer)));
}

// Avro duration: fixed(12) = uint32 months | uint32 days | uint32 millis, big-endian.
encodeDurationAsBase64(months = 0, days = 1, milliseconds = 0): string {
  const buffer = new ArrayBuffer(12);
  const view = new DataView(buffer);
  view.setUint32(0, months, false);
  view.setUint32(4, days, false);
  view.setUint32(8, milliseconds, false);
  return btoa(String.fromCharCode(...new Uint8Array(buffer)));
}

// Avro fixed(size): value's char codes, zero-padded or truncated to size.
encodeFixedAsBase64(size, value?): string {
  const bytes = new Uint8Array(size);
  if (value) for (let i = 0; i < Math.min(size, value.length); i++) bytes[i] = value.charCodeAt(i);
  return btoa(String.fromCharCode(...bytes));
}
```

Documented limits: decimal is capped at 64-bit (~18 significant digits — adequate
for the 19-digit financial precision in use, but it will overflow beyond that);
duration components are `uint32` (max ≈49 days of milliseconds); `precision` is
accepted for signature compatibility but does not affect the encoding.

Known gap carried forward: there is **no client-side Avro validation**. Structural
validity is only confirmed by calling the backend `/validate` endpoint.

---

## 12. Shared components and pipes

| Component | Selector | Inputs / outputs | Behaviour |
|---|---|---|---|
| `JsonViewerComponent` | `app-json-viewer` | `data` (required `unknown`), `indent` (2), `ariaLabel` (`'JSON content'`) | Pretty-prints; if `data` is a string it tries to parse and re-stringify, falling back to the raw string. Then escapes `&`, `<`, `>` and wraps tokens in `.json-key` / `.json-string` / `.json-number` / `.json-boolean` / `.json-null` spans, and passes the result through `bypassSecurityTrustHtml`. **The escape must happen before the highlight** — it is the only thing making the bypass safe. |
| `LoadingSpinnerComponent` | `app-loading-spinner` | `diameter` (48), `message` (`'Loading...'`) | `mat-progress-spinner` + caption. |
| `ConfirmationDialogComponent` | `app-confirmation-dialog` | `MAT_DIALOG_DATA: ConfirmationDialogData { title, message, confirmText?, cancelText?, confirmColor? }` | Closes with `true`/`false`. Inline template and styles. Currently unused by any feature — keep it as the sanctioned confirm pattern. |
| `ThemeToggleComponent` | `app-theme-toggle` | — | `mat-menu` of Light / Dark / System; trigger icon computed `light_mode` / `dark_mode` / `computer`. |
| `PaletteSelectorComponent` | `app-palette-selector` | — | `mat-menu` of the 7 palettes with swatches from `PaletteInfo.color`; marks the current one. |

| Pipe | Name | Signature |
|---|---|---|
| `DateFormatPipe` | `dateFormat` | `(value: string \| Date \| null \| undefined, formatStr = 'MMM d, yyyy HH:mm:ss')`. `parseISO` for strings, `isValid` guard, `''` for null/invalid. Uses `date-fns` — never `new Date()` in a template. |
| `JsonFormatPipe` | `jsonFormat` | `(value: unknown, indent = 2)`. Same parse-then-stringify logic as the viewer, without highlighting. |

Both pipes are pure (no `pure: false`) and are declared without `standalone: true`
(the Angular 21 default).

---

## 13. Design system

This is a hard contract, not a style preference, and it is machine-checked. The full
rules live in `.claude/skills/angular-frontend-design/SKILL.md` with reference
material under `references/{tokens,patterns,layout,material}.md`; the same directory
carries `assets/` — an app-agnostic copy of the whole system for bootstrapping.

### 13.1 Architecture

Three cascading layers, all applied to `<html>`:

```
:root                  light theme defaults
[data-theme='dark']    dark theme overrides
[data-palette='<id>']  brand palette (7), orthogonal to theme
```

Components consume `var(--token)` and never a literal colour. A hardcoded colour opts
out of dark mode and all 7 palettes simultaneously.

### 13.2 `src/styles.scss` — load order is load-bearing

```scss
@use 'material-theme';      // 1. Material's own CSS: structure, density, states
@use 'tokens';              // 2. the tokens every later layer consumes
@use 'base';                // 3. reset, body, links, code blocks, scrollbars
@use 'material-overrides';  // 4. re-skins Material with tokens — MUST follow 1
@use 'patterns';            // 5. shared UI vocabulary
@use 'a11y';                // 6. focus, helpers, skip link, reduced motion — LAST,
                            //    so reduced-motion beats every transition above
```
`_breakpoints.scss` is deliberately **not** in this list: it emits no CSS and is
`@use`d directly by the component stylesheets that need a media query.

### 13.3 `_material-theme.scss`

`mat.define-theme()` for light and dark, both with `primary: mat.$azure-palette`,
`tertiary: mat.$blue-palette`, `density: (scale: 0)`. Applied as
`html { @include mat.all-component-themes($light-theme) }` and
`html[data-theme='dark'] { @include mat.all-component-colors($dark-theme) }`.
Material supplies **structure only**; every colour is re-applied from tokens by
`_material-overrides.scss`. `mat.get-theme-color()` must never appear in a component.

### 13.4 Token contract

Semantic tokens (defined for both themes). The dark values are chosen for WCAG AA
contrast, not by algorithmic inversion.

| Group | Tokens |
|---|---|
| Surfaces | `--bg`, `--surface-1`, `--surface-2`, `--surface-3`, `--surface-hover`, `--surface-selected` |
| Text | `--text-1`, `--text-2`, `--text-3`, `--text-inverse` |
| Lines | `--border`, `--divider` |
| Status ×4 | `--{success,danger,warning,info}-{bg,text,border}` |
| Inputs | `--input-bg`, `--input-border`, `--input-text`, `--input-placeholder` |
| Elevation | `--shadow-1`, `--shadow-2` |
| Top bar | `--topbar-bg`, `--topbar-text`, `--topbar-border` |
| Code/JSON | `--code-bg`, `--code-border`, `--json-key`, `--json-string`, `--json-number`, `--json-boolean` |
| Chips | `--chip-bg`, `--chip-text`, `--chip-border`, `--chip-accent-{bg,border,text}` |

Light: `--bg: #f5f5f5`, `--surface-2: #ffffff`, `--text-1: rgba(0,0,0,.87)`,
`--topbar-bg: #1976d2`. Dark: `--bg: #121212`, `--surface-2: #242424`,
`--text-1: rgba(255,255,255,.92)`, `--topbar-bg: #1e1e1e`, and stronger shadows.
JSON colours in dark mode follow the VS Code dark palette.

**Palette tokens** are generated from a Sass map, so a palette cannot be partially
defined. Each entry supplies `primary` (Tailwind 500), `primary-rgb`,
`primary-hover` (600), `primary-active` (700), `primary-contrast`, `accent` (400),
`focus-rgb`, `chip-accent-text` (200/300); the `palette-tokens()` mixin emits the
12-token contract:

```
--primary --primary-rgb --primary-hover --primary-active --primary-contrast
--accent --accent-contrast --link --focus-ring
--chip-accent-bg --chip-accent-border --chip-accent-text
```

Emitted once into `:root` for blue (the no-attribute default) and once per
`[data-palette='<id>']`. Adding a palette means one map entry plus one
`PaletteInfo` — nothing else.

Two invariants:
1. **Palette tokens never express state.** A success message must read as success in
   all 7 palettes, so the status triplets are palette- and brand-independent.
2. **A semantic state is a triplet** — `bg` + `text` + `border`, all three or none.

### 13.5 Non-colour scales

- **Spacing:** px on a 4px grid — 4 / 8 / 12 / 16 / 24 / 32 / 48. 16px is the default
  unit (card padding, gaps, section rhythm); 24px separates page-level blocks.
  **Never `rem`.**
- **Type:** 11 / 12 / 13 / 14 / 16 / 18 / 20 / 24px. Weights **400, 500, 600 only** —
  never 700. Body font Roboto; monospace `'Roboto Mono', monospace`.
- **Radii:** 4px inputs and code, 6px banners, 8px cards / badges / tiles.
- **Motion:** transitions list properties explicitly — `0.2s ease` for
  theme-reactive properties (`background-color`, `color`, `border-color`), `0.15s ease`
  for tight interactions (row hover). Never `transition: all`. No `@keyframes`
  anywhere, which is why the reduced-motion block only needs to neutralise durations.
- **Breakpoints** (`_breakpoints.scss`, the only Sass-variable layer, because CSS
  custom properties cannot be used inside `@media`):
  `$bp-sm: 600px`, `$bp-md: 768px`, `$bp-lg: 960px`, `$bp-xl: 1280px`, with
  `@mixin below($bp)` (max-width, `$bp - 1px`) and `@mixin from($bp)`.
  Prefer `repeat(auto-fit, minmax(Npx, 1fr))` and no breakpoint at all; use
  `BreakpointObserver` for behavioural changes.

### 13.6 Global patterns (`_patterns.scss`)

Consume these from templates rather than re-declaring their anatomy in a component;
a component contributes only its own layout delta.

- `.json-key` / `.json-string` / `.json-number` / `.json-boolean` / `.json-null`.
- Chip/pill status classes `.status-success|.success`, `.status-error|.status-failed|.error`,
  `.status-warning|.warning`, `.status-info|.info` — each sets the full triplet with
  `!important` to beat MDC.
- `.status-badge` — 28×28 inline-flex centred box, radius 8px, `flex-shrink: 0`, with
  an 18px `mat-icon` set to `display: block` to avoid baseline drift. Modifiers:
  `--success`, `--error`/`--failed`, `--warning`, `--info`, `--pending`.
- `.error-banner` — flex row, 12px gap, 12/16 padding, radius 6px, danger triplet;
  the inner `span` takes `flex: 1` so a trailing action button sits flush right.
  Always paired with `role="alert"`. `.error-banner--warning` is the
  degraded-but-recoverable variant.
- `.snackbar-{success,error,warning,info}` — set `--mdc-snackbar-*` custom properties.
  These are the one sanctioned place for literal colours outside `_tokens.scss`,
  because they are fixed high-contrast toast colours in both themes.

`_base.scss` covers the box-sizing reset, full-height `html`/`body`, body font and
themed background with a 0.2s transition, link colours and focus, `pre`/`code`
styling, and a dark-mode-only webkit scrollbar treatment.

`_a11y.scss` provides the global `:focus-visible` ring (`2px solid var(--focus-ring)`,
`outline-offset: 2px`), `.visually-hidden`, the `.skip-link` (fixed, `z-index: 1100`
above the 1000 header, translated off-screen until `:focus`), and the
`prefers-reduced-motion` block.

`_material-overrides.scss` is the **only** file where `!important` is acceptable, and
each occurrence should say what MDC behaviour it fights. It re-skins cards, dialog
surfaces, the drawer, tables (header row, row hover, cell borders), the paginator,
form fields (notched-outline colours for rest/hover/focus, input and placeholder
colour), and more.

### 13.7 Enforcement — `npm run audit:design`

A bash+Python script scanning `src/app/**` (both `.scss` files and inline
`styles:` template literals in `.ts`), with comments stripped first.

**Errors (exit 1):**
- `literal-colour` — any hex, `rgb()`/`rgba()`, or bare named colour. The single
  exception is `rgba(var(--token), a)`, which is stripped before matching.
- `undefined-token` — a `var(--x)` whose `--x` is defined nowhere in `src/styles`
  (including tokens emitted from a mixin body). `--mdc-*` and `--mat-*` are exempt.
  This rule exists because an undefined custom property fails **silently** — a
  missing `--surface-selected` hid a broken selected-row state in `schema-list` for
  months.
- `mat-get-theme-color`, `rem-unit`, `transition-all`.

**Tracked warning (non-blocking):** `!important` in a component stylesheet, with two
files grandfathered as known legacy debt
(`schema-list.component.scss`, `sidebar.component.scss`). Reported so the count
cannot quietly grow.

Run it before committing any style change.

### 13.8 Pre-paint theme boot

`src/index.html` runs an inline IIFE in `<head>` **before any stylesheet**:

1. Read `localStorage['theme-mode']`; `dark`/`light` win, anything else falls back to
   `matchMedia('(prefers-color-scheme: dark)')`.
2. Set `data-theme` on `<html>` and update `<meta name="color-scheme">`.
3. Read `localStorage['palette']`, validate against the 7 ids, default `blue`, set
   `data-palette`.

Without this the app flashes light on every dark-mode reload. The head also carries
`<meta name="color-scheme" content="light dark">`, the favicon, `<base href="/">`,
and preconnected Google Fonts links for `Roboto:wght@300;400;500`,
`Roboto+Mono:wght@400;500` and `Material+Icons`. Page title:
`Mockafka - Event Publisher`.

> Note for restricted networks: fonts and Material icons are loaded from
> `fonts.googleapis.com` / `fonts.gstatic.com` at runtime. If the deployment
> environment blocks egress, self-host them — icons silently degrade to ligature
> text otherwise.

---

## 14. Build, packaging and deployment

### 14.1 Bundle

`npm run build` → `dist/bb-credit-domain_mockafka-frontend/browser/` with hashed
filenames. Budgets: initial 500 kB warn / 1 MB error; any single component
stylesheet 4 kB warn / 8 kB error. Current initial bundle is roughly 800 kB, i.e.
already over the warning threshold and inside the error threshold — treat 1 MB as a
hard ceiling when adding dependencies.

### 14.2 Docker image

Single-stage `nginx:alpine` that copies a **pre-built** bundle — the CI builds the
Angular app and Docker only packages it:

```dockerfile
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/conf.d/default.conf
# make the PID path writable so nginx can run non-root
RUN sed -i 's|pid /run/nginx.pid;|pid /tmp/nginx.pid;|g'     /etc/nginx/nginx.conf && \
    sed -i 's|pid /var/run/nginx.pid;|pid /tmp/nginx.pid;|g' /etc/nginx/nginx.conf
ARG location=dist
COPY ${location}/bb-credit-domain_mockafka-frontend/browser /usr/share/nginx/html
RUN mkdir -p /var/cache/nginx/{client,proxy,fastcgi,uwsgi,scgi}_temp /tmp/nginx && \
    chmod -R 777 /var/cache/nginx /var/run /run && \
    chmod -R 755 /usr/share/nginx/html && chmod 777 /tmp
USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

The `chmod 777` grants and the writable PID relocation exist so the container can run
as a non-root user under a restrictive `PodSecurityContext`. `777` on the cache and
run directories is broader than necessary — a hardening pass should narrow these to
the `nginx` user/group.

### 14.3 NGINX site config (`nginx.conf`)

`listen 8080`, root `/usr/share/nginx/html`, `index index.html`.

| Location | Behaviour |
|---|---|
| `/api/` | `proxy_pass http://events-management-service:8080` (short in-namespace service name), HTTP/1.1, `Host`/`X-Real-IP`/`X-Forwarded-For`/`X-Forwarded-Proto` set, `proxy_read_timeout 300s`, `proxy_connect_timeout 75s` |
| `/` | `try_files $uri $uri/ /index.html` — SPA deep links |
| `\.(js\|css\|png\|jpg\|jpeg\|gif\|ico\|svg\|woff\|woff2\|ttf\|eot)$` | `expires 1y`, `Cache-Control: public, immutable` |
| `= /index.html` | `no-cache, no-store, must-revalidate`, `expires 0` |
| `/health` | `200 "healthy\n"`, access log off |
| `= /healthz` | `200 "ok\n"`, access log off |

Also: gzip on with `gzip_vary`, for text, css, json, js and xml; security headers
`X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`,
`X-XSS-Protection: 1; mode=block`.

The 300s API read timeout is deliberate: a large bulk publish is one long blocking
POST.

> Two documentation defects to resolve rather than copy. (a) `nginx-main.conf` is a
> full main-config replacement that the Dockerfile never copies — the image relies on
> the `sed` edits to the stock `nginx.conf` instead. Either `COPY` it or delete it.
> (b) `IMPLEMENTATION-SUMMARY.md` and `DEPLOYMENT-GUIDE.md` describe port **80**
> throughout, while the Dockerfile and site config both use **8080**. 8080 is
> correct — the docs predate the non-root change. Helm `service.port`,
> `targetPort`, `containerPort` and both probe ports must be 8080.

### 14.4 Kubernetes expectations

Owned by the GitOps repo, recorded here as the contract the image assumes:

- `containerPort: 8080`; service port and targetPort 8080.
- `livenessProbe` / `readinessProbe` → `GET /health` on 8080.
- Runs as the `nginx` user (uid/gid 101), all capabilities dropped, no
  `NET_BIND_SERVICE` needed (unprivileged port).
- Resource envelope for a static NGINX pod: requests ~50m CPU / 64Mi,
  limits ~200m CPU / 128Mi.
- The backend must be reachable in-namespace as `events-management-service:8080`.
- No WebSocket or long-timeout ingress annotations are required (they were only
  needed by the historical `ng serve` deployment); a raised
  `proxy-body-size` is still useful for large payloads.

### 14.5 CI/CD — `.github/workflows/build-deploy.yaml`

Triggers: `workflow_dispatch`, or a PR against `main`/`develop`/`release`
(`opened`, `reopened`, `synchronize`, `closed`) touching `src/**`, `certs/**`,
`Dockerfile` or `.github/workflows/*.yaml`. Concurrency is grouped by target branch
without cancel-in-progress. Permissions: `id-token: write`, `contents: write`,
`pull-requests: write`.

`build-and-container` (`ubuntu-22`):
1. Checkout; Node 22.
2. `PROJECT_VERSION` scraped from `package.json` with a grep.
3. JFrog CLI setup + `jf rt ping`; `jf npm-config` pointing resolve and deploy at
   `$JF_REPO`; `jf npm install` / `run build` / `publish`, then
   `build-collect-env` and `build-publish`.
4. `docker buildx build --platform linux/amd64 --build-arg location=./dist`,
   tagging `${JF_BASE_URL}/${DOCKER_REPO}/${BUILD_NAME}:${PROJECT_VERSION}-${GITHUB_SHA::8}`.
5. Login to the JFrog registry, `jf docker push`, publish Docker build info.

Then, by environment: `deploy-dev` (every build), `deploy-int` (merged PR into
`develop`), `create-release` + `deploy-qa` + `deploy-prod` (merged PR on `release` —
prod gated behind QA). Each deploy job calls `capitec-odin/action-deploy@v2` against
the GitOps repo with the image and target env, then `jf rt build-promote` to the
matching status (`DEV`/`INT`/`QA`/`PROD`). `create-release` cuts a GitHub prerelease
tagged with the package version and appends the image reference to the notes.

Note the version comes from `package.json`, which is still `0.0.0` — image tags are
currently distinguished only by the commit SHA suffix. Start versioning it.

`delete-branch.yaml` deletes the head branch after any PR merge, skipping
`main`/`develop`/`release`, and tolerating a 422 (already deleted).

`dependabot.yml` covers only the `devcontainers` ecosystem, weekly — npm
dependencies are **not** currently auto-updated. Adding an `npm` entry is a cheap
improvement.

Branching model: feature branches off `develop`; PR into `develop`; promotion through
`release` to `main`.

---

## 15. Cross-cutting requirements

### 15.1 Accessibility (WCAG 2.1 AA, must pass axe)

- Every page provides one `<h1>`; sections use `aria-labelledby` pointing at their
  heading.
- The layout provides a skip link to `#main-content`; `<main>` has `tabindex="-1"`
  so the link can focus it.
- Decorative `mat-icon`s carry `aria-hidden="true"` and the accessible name goes on
  the wrapping element (`aria-label` + `title` on `.status-badge`).
- Icon-only buttons always have `aria-label`.
- `aria-current` binds to `'page'` or `null` — **never** `false`.
- `role="alert"` on error banners; `role="status"` + `aria-live="polite"` on the
  publish requirements checklist; `role="search"` on the message filter form;
  `role="list"`/`"listitem"` on the validation error list.
- Tables carry `aria-label`; the paginator is labelled.
- Focus is visible everywhere via the global `:focus-visible` ring and
  `var(--focus-ring)`, which is palette-reactive.
- `prefers-reduced-motion` neutralises all transition durations.
- Colour contrast: both themes' text tokens are chosen for AA; status colours are
  verified against their own backgrounds.

Open items: the dashboard's clickable `div`s (§10.2) and the `mat-select`-embedded
search inputs in the schema/topic selectors (which stop keydown propagation to keep
the select from hijacking typing — verify screen-reader behaviour if reworked).

### 15.2 Performance

- Route-level lazy loading for all four features; `provideAnimationsAsync()`.
- `OnPush` everywhere (fix `BulkPublishComponent`), signals + `computed()` for
  derived state.
- Immutable signal updates only — `set`/`update`, never `mutate`.
- All `@for` blocks declare `track`.
- Static assets are immutable-cached for a year; `index.html` is never cached.
- The `1 + N` schema-version fan-out (§9.1) is the known hot spot.

### 15.3 Security

- No secrets in the frontend. No tokens stored. `localStorage` holds only
  `theme-mode` and `palette`.
- The only `bypassSecurityTrustHtml` in the codebase is in `JsonViewerComponent`,
  and it operates on text that has already had `&`, `<` and `>` escaped. Any change
  to that method must preserve the escape-before-highlight order.
- `navigator.clipboard.writeText` is used for schema copy; it requires a secure
  context.
- NGINX sets `X-Frame-Options`, `X-Content-Type-Options` and `X-XSS-Protection`.
  A CSP is **not** currently set — adding one would need to account for the inline
  theme-boot script (use a nonce or hash) and the Google Fonts origins.
- User-authored JSON is only ever parsed with `JSON.parse` inside `try/catch` —
  never `eval`.

---

## 16. Testing

### 16.1 Setup

`ng test` → `@angular/build:unit-test` → Vitest with jsdom. Specs are colocated as
`*.spec.ts` and compiled by `tsconfig.spec.json` with `vitest/globals`.

```bash
npm test                              # all
npm test -- --coverage
npm test -- --watch
npm test -- --include='**/encoding.spec.ts'
```

### 16.2 Component test pattern

```ts
await TestBed.configureTestingModule({
  imports: [ComponentUnderTest, NoopAnimationsModule],
  providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
}).compileComponents();
```
`NoopAnimationsModule` is mandatory because the app provides animations
asynchronously. `provideHttpClient()` must come before `provideHttpClientTesting()`.
Assertions query the rendered DOM (`fixture.nativeElement.querySelector`) rather
than reaching into protected component members. Use `vi.spyOn` for output emissions.

### 16.3 Required coverage

Every component and pipe has a spec. Non-negotiable areas:

1. **Encoding utilities** (`encoding.spec.ts`, 12 tests) — pure-function copies of
   the three encoders, asserting Base64 shape (`/^[A-Za-z0-9+/]+=*$/`),
   `atob` round-trip, scale sensitivity, negatives, zero, large values, and fixed
   padding/truncation.
2. **Template generation** (`publish-event.component.spec.ts`, 13 tests) — decimal,
   duration and fixed produce Base64 strings; nested records, unions and arrays
   recurse; empty and non-record schemas return `{}`.
3. Service happy path plus the error-fallback substitution for each method.
4. Layout: header title and menu emission, sidebar nav item count and first label,
   main layout container presence.

### 16.4 Known-failing test

`sidebar.component.spec.ts` asserts 4 nav items against a 5-item array (§10.1). Fix
the assertion — do not reproduce the failure.

### 16.5 Manual verification

`TESTING_GUIDE.md` documents the end-to-end smoke path, which should survive any
rewrite: open `/publish`, select a schema with decimal/fixed/duration fields, click
**Use Template**, confirm those fields are Base64 strings, **Validate** (expect a
pass), select a topic, **Publish** (expect success), then confirm the message appears
in Message History. Repeat across every registry subject to catch schema-specific
generation gaps.

---

## 17. Coding conventions

From `AGENTS.md`, in force for all new code:

**TypeScript**
- Strict checking; prefer inference where obvious; never `any` — use `unknown`.

**Angular**
- Standalone components always; **never** write `standalone: true` (it is the v20+
  default).
- Signals for state; `computed()` for derived; `input()`/`output()` functions, not
  decorators.
- `ChangeDetectionStrategy.OnPush` on every component.
- Lazy-load every feature route.
- No `@HostBinding`/`@HostListener` — use the `host` object.
- `NgOptimizedImage` for static images.
- Inline templates for small components; external files use paths relative to the
  `.ts`.
- Reactive forms over template-driven.
- `class`/`style` bindings, never `ngClass`/`ngStyle`.
- Native control flow (`@if`/`@for`/`@switch`), never the legacy `*` directives.
- No arrow functions in templates; no reliance on globals like `new Date()`.
- `inject()` over constructor injection; `providedIn: 'root'` singletons; one
  responsibility per service.

**Documented deviations** (match the surrounding code, do not "fix" in passing):
1. No `async` pipe — subscribe in TS, push into signals, read signals in templates.
2. `BulkPublishComponent` violates several rules (§10.4) and is the thing to bring
   into line, not to imitate.

**Styling** — see §13. Never hardcode a colour; run `npm run audit:design` before
committing style changes.

### 17.1 Component scaffolder

`./scripts/generate-component.sh <name> [--feature | <path>]` generates a
convention-compliant standalone component (OnPush, signal inputs/outputs, ARIA,
spec file). `--help` documents it; `scripts/README.md` has the detail. Prefer it
over `ng generate` so the conventions above are applied by default.

---

## 18. Build order for a from-scratch implementation

Each step is independently verifiable.

1. **Skeleton** — `ng new` with the Angular 21 application builder, SCSS. Apply
   `angular.json` (§5.1, especially `stylePreprocessorOptions`), the three
   tsconfigs, Prettier config, npm scripts, `.nvmrc`, `proxy.conf.json`.
   *Verify:* `npm run build` and `npm test` both succeed on the empty app.
2. **Design system** — copy `src/styles/` in the order of §13.2, `src/index.html`
   including the pre-paint boot script and fonts, and `scripts/audit-design-tokens.sh`
   wired to `npm run audit:design`. Do this **before** any component; the rules decay
   without the check.
   *Verify:* `npm run audit:design` passes on an empty `src/app`.
3. **Theming** — `theme.model`, `palette.model`, `ThemeService`, `PaletteService`,
   `ThemeToggleComponent`, `PaletteSelectorComponent`.
   *Verify:* toggling theme and palette repaints, survives reload, no flash on a
   dark-mode reload.
4. **Core plumbing** — all models (§7), `api.config.ts`, both interceptors,
   `NotificationService`, `app.config.ts`.
5. **Layout and routing** — `app.routes.ts` with four lazy features (stub
   components), `MainLayoutComponent`, `HeaderComponent`, `SidebarComponent`, skip
   link.
   *Verify:* deep links, wildcard redirect, sidenav switching `side`↔`over` at the
   handset breakpoint, keyboard-reachable skip link.
6. **Data services** — `SchemaService`, `TopicService`, `EventService`,
   `PublishedMessageService`, each with the exact error-fallback semantics of §9.
   *Verify:* unit tests against `HttpTestingController` for the happy path and the
   fallback of every method.
7. **Shared components and pipes** — `JsonViewerComponent` (escape before
   highlight), `LoadingSpinnerComponent`, `ConfirmationDialogComponent`,
   `DateFormatPipe`, `JsonFormatPipe`.
8. **Avro template generator** — extract §11 as a pure module with the encoding and
   template-generation test suites of §16.3. Build this before the publish screen;
   it is the part with real behavioural risk.
9. **Schema browser** — `SchemaListComponent` (search, domain grouping, expansion
   set), `SchemaVersionSelectorComponent`, `SchemaDetailComponent` (field types,
   copy, JSON view), the container with `?subject=` deep linking.
10. **Publish** — `SchemaSelectorComponent`, `TopicSelectorComponent`,
    `JsonEditorComponent`, `ValidationResultsComponent`, then the container with the
    full derived-state and invalidation rules of §10.3.
    *Verify:* the §16.5 manual path end to end.
11. **Message history** — `MessageFiltersComponent` (inclusive date normalisation),
    `MessageTableComponent` (server-side paging), `MessageDetailComponent`,
    `ReplayDialogComponent`, container with query-param-driven filters.
12. **Bulk publish** — the form, validators, `randomKeys`/`fixedKey` interlock,
    overrides parsing, results table. Written to convention this time (§10.4).
13. **Dashboard** — stats, recent activity, schema list, cross-navigation. Use real
    buttons for the clickable tiles.
14. **Packaging** — `Dockerfile`, `nginx.conf` (port 8080 throughout), health
    endpoints.
    *Verify:* `docker build` then `docker run -p 8080:8080`; check `/health`, a deep
    link such as `/schemas`, immutable caching on a hashed asset, and `no-store` on
    `index.html`.
15. **CI/CD** — the JFrog build/push/promote workflow and the branch-delete
    workflow; align Helm values with §14.4.
16. **Cleanup carried from this spec** — resolve every item in §19 explicitly
    rather than porting it.

---

## 19. Known defects and deviations

Carried forward deliberately so a rebuild decides about each one instead of
inheriting it silently.

| # | Item | Location | Recommendation |
|---|---|---|---|
| 1 | Stale nav-item count assertion (4 vs 5) — currently failing | `sidebar.component.spec.ts` | Fix the assertion |
| 2 | `isActive()` reads `window.location.pathname`; non-reactive, breaks the no-globals rule | `sidebar.component.ts` | Use `Router`/`RouterLinkActive` |
| 3 | `BulkPublishComponent`: `standalone: true`, no `OnPush`, `CommonModule`, public mutable signals, `Record<string, any>` | `bulk-publish.component.ts` | Bring to convention |
| 4 | Correlation-id interceptor overwrites a caller-supplied `X-Correlation-Id` | `correlation-id.interceptor.ts` | Only set when absent |
| 5 | `ThemeService.ngOnDestroy` never runs (no `implements`, root singleton) | `theme.service.ts` | Drop it or use `DestroyRef` |
| 6 | Loading flags cleared in `tap`, so an early unsubscribe leaves them stuck | `event.service.ts` | Use `finalize` |
| 7 | `getSchema(subject, 0)` silently resolves to `latest` (truthiness check) | `schema.service.ts` | Compare against `undefined`/`null` |
| 8 | `route.queryParams` and `BreakpointObserver` subscriptions are never torn down | several containers | `takeUntilDestroyed()` |
| 9 | Dashboard tiles / rows are clickable `div`s — not keyboard accessible | `dashboard.component.html` | Use `<button type="button">` |
| 10 | Dead code: `PageRequest`, `ReplayResponse`, `BulkPublishProgress`, `MessageStats`, `getMessage`, `updateSearchParams`, `ConfirmationDialogComponent`, `withComponentInputBinding()`, `versionsSignal` in `schema-selector` | various | Wire up or delete |
| 11 | `MessageSearchParams.idempotencyKey` / `messageKey` sent but not surfaced in the UI | `message-filters` | Add controls or drop the params |
| 12 | Bulk-publish `eventType` options are hardcoded, repayments-specific | `bulk-publish.component.ts` | Move to config or the backend |
| 13 | Docs say port 80; Dockerfile and NGINX use 8080 | `IMPLEMENTATION-SUMMARY.md`, `DEPLOYMENT-GUIDE.md` | Correct the docs to 8080 |
| 14 | `nginx-main.conf` is never copied into the image | `Dockerfile` | `COPY` it or delete the file |
| 15 | `chmod -R 777` on cache/run dirs | `Dockerfile` | Narrow to the `nginx` user/group |
| 16 | Vestigial `vite.config.ts`, `.env` (Fastify vars), `.devcontainer` referencing a non-existent `source/` | repo root | Delete |
| 17 | `package.json` version pinned at `0.0.0`; image tags differ only by SHA | `package.json` | Adopt real versioning |
| 18 | Dependabot covers only devcontainers, not npm | `.github/dependabot.yml` | Add the `npm` ecosystem |
| 19 | Duplicate unused `app.html` / `app.scss` alongside the inline root template | `src/app/` | Delete |
| 20 | `SchemaService.loadSubjects()` is `1 + N` requests and runs on four screens' init | `schema.service.ts` | Cache, or ask for a combined endpoint |
| 21 | No client-side Avro validation — structural validity requires a backend round-trip | publish flow | Consider an Avro JS library |
| 22 | No CSP header | `nginx.conf` | Add one, accounting for the inline boot script and Google Fonts |
| 23 | Fonts and Material icons load from Google CDN at runtime | `index.html` | Self-host if egress is restricted |
| 24 | No linter (ESLint) configured | repo root | Add `angular-eslint` |
| 25 | Bulk publish is one blocking POST; `BulkPublishProgress` suggests streaming was intended | backend + UI | Consider SSE/websocket progress for large runs |
