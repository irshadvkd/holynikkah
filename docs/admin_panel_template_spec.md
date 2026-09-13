# Template Engine — Admin Panel & API Specification

> **Purpose:** This document is a build spec for the **Admin Panel + Backend API** that powers
> dynamically configurable "templates" in the HolyNikah Flutter app. Hand this file to the
> admin-panel/backend team (or paste it into Cursor) to implement the system.
>
> **Goal:** Admins must be able to create and manage templates entirely from the admin panel —
> the **background image, fields, input types, validation rules, positioning, and styling** —
> with **zero Flutter app releases** required to add or change a template.

---

## 1. Background & Concept (Server-Driven UI)

Today the Flutter app hardcodes each template (fixed fields, fixed positions, fixed styling).
We are moving to **Server-Driven UI (SDUI)**:

- The admin panel produces a **JSON definition** per template.
- The backend API serves these definitions.
- The Flutter app has a **single generic renderer** that builds both:
  1. the **input form** (page 1), and
  2. the **preview canvas** (page 2, exported as a PNG image)
  from the JSON.

The app side is out of scope for this team; **your deliverables are the API + admin panel
that produce and manage valid template JSON** described below.

---

## 2. Core Data Model

A **Template** has three parts:

| Part | Meaning |
|------|---------|
| `canvas` | The drawing surface: aspect ratio + background. |
| `fields` | The form inputs the end-user fills in (with input type + validation). |
| `elements` | What is drawn on the canvas (position + style), some bound to field values. |

### 2.1 Positioning rule (CRITICAL)

All positions and sizes are **relative fractions between `0.0` and `1.0`**, never pixels.

- `x` = left offset as fraction of canvas width
- `y` = top offset as fraction of canvas height
- `w` = width as fraction of canvas width
- `h` = height as fraction of canvas height

This guarantees the template renders identically on every device and at any export
resolution. The visual editor must convert drag/resize pixel coordinates into these fractions
before saving.

---

## 3. JSON Schema

### 3.1 Top-level Template object

```jsonc
{
  "id": "vip_2",                 // string, unique, immutable
  "schemaVersion": 1,            // int, bump on breaking schema changes
  "name": "Nikkah Proposal",     // string, shown in app + admin
  "type": "vip",                 // enum: "vip" | "normal"
  "status": "published",         // enum: "draft" | "published" | "archived"
  "thumbnail": "https://cdn.app/templates/vip_2/thumb.png",
  "createdAt": "2026-06-25T12:00:00Z",
  "updatedAt": "2026-06-25T12:00:00Z",
  "canvas": { /* see 3.2 */ },
  "fields":  [ /* see 3.3 */ ],
  "elements":[ /* see 3.4 */ ]
}
```

### 3.2 `canvas`

```jsonc
{
  "aspectRatio": 0.75,           // number, width / height (e.g. 3/4 = 0.75)
  "background": {
    "type": "image",             // enum: "image" | "color"
    "source": "https://cdn.app/templates/vip_2/bg.png", // required if type=image
    "color": "#000000"           // hex, required if type=color
  }
}
```

### 3.3 `fields[]` — one entry per user input

```jsonc
{
  "key": "age",                  // string, unique within template, [a-z0-9_]
  "label": "വയസ്സ്",             // string, supports Unicode/Malayalam
  "hint": "Enter age",           // string, optional
  "inputType": "number",         // enum below
  "keyboard": "number",          // enum below
  "required": true,              // bool
  "defaultValue": "",            // string, optional
  "maxLength": 40,               // int, optional
  "validation": {                // object, optional, all keys optional
    "minLength": 2,
    "maxLength": 40,
    "min": 18,                   // numeric min (inputType=number)
    "max": 80,                   // numeric max (inputType=number)
    "regex": "^[A-Za-z ]+$",     // string regex (must be valid; validate server-side)
    "errorMessage": "Invalid age"
  }
}
```

**`inputType` enum:** `text` | `number` | `phone` | `email` | `multiline` | `date` | `dropdown`

- For `dropdown`, add `"options": ["A", "B", "C"]`.

**`keyboard` enum:** `text` | `number` | `phone` | `email`

> The Flutter app maps `inputType=number` to digits-only entry, `email` to email keyboard, etc.
> The admin panel must expose these as dropdowns, not free text.

### 3.4 `elements[]` — what is drawn on the canvas

Every element has a `type`, a `rect` (relative position), and optional `style`.

```jsonc
{
  "id": "el_box_1",              // string, unique within template
  "type": "box",                // enum below
  "rect": { "x": 0.12, "y": 0.62, "w": 0.76, "h": 0.34 },
  "style": { /* see 3.5 */ },
  "field": null,                 // string|null, references fields[].key (for bound types)
  "label": null,                // string|null, static label (for boundRow / text)
  "text": null,                 // string|null, static text (for text type)
  "children": [ /* nested elements, for type=box */ ]
}
```

**`type` enum:**

| type | Description | Uses |
|------|-------------|------|
| `imageSlot` | The end-user's uploaded photo. Usually full-canvas background. | `rect`, `style.fit` |
| `box` | A styled container that can hold `children`. | `rect`, `style`, `children` |
| `text` | Static text. | `text`, `style` |
| `boundField` | Displays the value of a field (no label). | `field`, `style` |
| `boundRow` | Displays `label : value`. | `label`, `field`, `style` |
| `image` | A static decorative image (logo, frame). | `style.source`, `rect` |

### 3.5 `style` object (all keys optional)

```jsonc
{
  "backgroundColor": "#FFFFFF",  // hex (#RRGGBB or #AARRGGBB)
  "color": "#032544",            // text color, hex
  "fontSize": 16,                // number (logical px; app scales)
  "fontWeight": 700,             // 100..900
  "fontFamily": "NotoSansMalayalam", // must be a supported font (see 6)
  "align": "center",             // enum: left | center | right
  "borderRadius": 6,             // number
  "padding": 14,                 // number (uniform) OR
  "paddingLTRB": [12, 14, 12, 14],
  "fit": "cover",                // for imageSlot/image: cover|contain|fill
  "source": "https://...",       // for image type
  "opacity": 1.0,                // 0..1
  "lineHeight": 1.5
}
```

---

## 4. Full Example (the current "VIP Template 2")

```json
{
  "id": "vip_2",
  "schemaVersion": 1,
  "name": "Nikkah Proposal",
  "type": "vip",
  "status": "published",
  "thumbnail": "https://cdn.app/templates/vip_2/thumb.png",
  "canvas": {
    "aspectRatio": 0.75,
    "background": { "type": "image", "source": "https://cdn.app/templates/vip_2/bg.png" }
  },
  "fields": [
    { "key": "title",     "label": "Title",        "inputType": "text",   "keyboard": "text",   "required": true, "maxLength": 40 },
    { "key": "age",       "label": "വയസ്സ്",        "inputType": "number", "keyboard": "number", "required": true, "validation": { "min": 18, "max": 80 } },
    { "key": "ideal",     "label": "ആദർശം",        "inputType": "text",   "keyboard": "text",   "required": true },
    { "key": "height",    "label": "ഉയരം",         "inputType": "text",   "keyboard": "text",   "required": true },
    { "key": "education", "label": "വിദ്യാഭ്യാസം",  "inputType": "text",   "keyboard": "text",   "required": true },
    { "key": "financial", "label": "സാമ്പത്തികം",   "inputType": "text",   "keyboard": "text",   "required": true },
    { "key": "place",     "label": "സ്ഥലം",        "inputType": "text",   "keyboard": "text",   "required": true }
  ],
  "elements": [
    {
      "id": "el_photo",
      "type": "imageSlot",
      "rect": { "x": 0, "y": 0, "w": 1, "h": 1 },
      "style": { "fit": "cover" }
    },
    {
      "id": "el_card",
      "type": "box",
      "rect": { "x": 0.12, "y": 0.60, "w": 0.76, "h": 0.36 },
      "style": { "backgroundColor": "#FFFFFF", "borderRadius": 6, "padding": 14 },
      "children": [
        { "id": "el_title", "type": "boundField", "field": "title",
          "style": { "fontSize": 16, "fontWeight": 700, "color": "#032544", "align": "center", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_age",    "type": "boundRow", "label": "വയസ്സ്",      "field": "age",       "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_ideal",  "type": "boundRow", "label": "ആദർശം",      "field": "ideal",     "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_height", "type": "boundRow", "label": "ഉയരം",       "field": "height",    "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_edu",    "type": "boundRow", "label": "വിദ്യാഭ്യാസം","field": "education", "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_fin",    "type": "boundRow", "label": "സാമ്പത്തികം", "field": "financial", "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } },
        { "id": "r_place",  "type": "boundRow", "label": "സ്ഥലം",      "field": "place",     "style": { "fontSize": 13, "color": "#000000DE", "fontFamily": "NotoSansMalayalam" } }
      ]
    }
  ]
}
```

---

## 5. REST API Contract

Base path: `/api/v1`

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| `GET`  | `/templates?type=vip&status=published` | List templates (lightweight: id, name, type, thumbnail, updatedAt). | App + Admin |
| `GET`  | `/templates/{id}` | Full template definition (the JSON above). | App + Admin |
| `POST` | `/admin/templates` | Create template (body = template JSON minus id/timestamps). | Admin only |
| `PUT`  | `/admin/templates/{id}` | Update template. | Admin only |
| `PATCH`| `/admin/templates/{id}/status` | Change status (draft/published/archived). | Admin only |
| `DELETE`| `/admin/templates/{id}` | Soft-delete (set status=archived). | Admin only |
| `POST` | `/admin/uploads` | Upload background/thumbnail image → returns CDN URL. | Admin only |

### 5.1 List response

```json
{
  "data": [
    { "id": "vip_2", "name": "Nikkah Proposal", "type": "vip", "thumbnail": "https://cdn.app/.../thumb.png", "updatedAt": "2026-06-25T12:00:00Z" }
  ],
  "meta": { "total": 1, "page": 1, "pageSize": 20 }
}
```

### 5.2 Errors

Standard JSON error shape:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "field 'age' has invalid regex", "details": [ ... ] } }
```

### 5.3 Caching / performance

- `GET /templates` and `GET /templates/{id}` should send `ETag` / `Cache-Control` so the app can cache.
- The app caches the last successful response to keep templates working offline.

---

## 6. Constraints the Admin Panel MUST enforce

These are validated **server-side on save** (never trust the editor alone):

1. **`id`** unique, immutable, slug format `[a-z0-9_]+`.
2. **`canvas.aspectRatio`** > 0.
3. **Field keys** unique within a template, slug format.
4. **`elements[].field`** (for `boundField`/`boundRow`) must reference an existing `fields[].key`.
5. **`rect`** values each within `0.0..1.0`; `x + w <= 1.0` and `y + h <= 1.0` (warn if out of bounds).
6. **`validation.regex`** must compile as a valid regex (reject bad patterns so the app can't crash).
7. **Colors** must be valid hex `#RRGGBB` or `#AARRGGBB`.
8. **`fontFamily`** must be one of the **supported fonts** list (see below). Reject unknown fonts.
9. **`fontWeight`** in `{100,200,...,900}`.
10. **`status=published`** only allowed if the template passes full validation.
11. Bumping the schema in an incompatible way requires incrementing `schemaVersion`.

### Supported fonts (initial)

`Inter`, `Poppins`, `NotoSansMalayalam`. (Malayalam labels REQUIRE `NotoSansMalayalam`.)
Any addition to this list must be coordinated with the Flutter team (font must be bundled or
runtime-loadable).

---

## 7. Admin Panel — Visual Editor Requirements

The editor is a web app that outputs valid template JSON. Required capabilities:

### 7.1 Canvas editor
- Render the canvas at the configured `aspectRatio` with the background image.
- **Drag & drop** elements; **resize** via handles. Convert pixel geometry → relative `rect`.
- Snapping/guides and a live preview using placeholder values.
- Layer ordering (z-index follows array order; allow reorder).

### 7.2 Field manager
- Add/edit/delete fields.
- Pick `inputType` and `keyboard` from dropdowns.
- Toggle `required`; set `maxLength`, `min`, `max`, `regex`, `errorMessage`.
- For `dropdown` inputType, manage the `options` list.
- Live "form preview" panel showing how the generated form will look.

### 7.3 Element manager
- Add `box`, `text`, `boundField`, `boundRow`, `image`, `imageSlot`.
- Bind `boundField`/`boundRow` to a field via a dropdown of existing keys.
- Style controls: color pickers (with alpha), font family/size/weight dropdowns, alignment,
  border radius, padding, opacity, image fit.

### 7.4 Lifecycle
- Save as **draft**; **publish** (runs full validation); **archive**.
- Upload background + auto-generate thumbnail.
- Show validation errors inline before allowing publish.

### 7.5 Recommended editor tech
- Canvas: React + Konva.js or Fabric.js (good for drag/resize → coordinates).
- Form-state & validation: react-hook-form + zod (mirror the schema rules in zod).
- Persisted via the REST API in section 5.

---

## 8. Versioning & Compatibility

- The app reads `schemaVersion`. If it's **higher** than the app supports, the app should
  ignore unknown `elements[].type` and unknown `style` keys gracefully (forward-compatible).
- Therefore: **only add new optional fields/types** within a `schemaVersion`. Removing or
  renaming keys, or changing semantics, requires a `schemaVersion` bump and Flutter coordination.

---

## 9. Acceptance Criteria (Definition of Done)

- [ ] CRUD + status endpoints implemented per section 5, with auth.
- [ ] Image upload endpoint returns CDN URLs; thumbnails generated.
- [ ] Server-side validation enforces every rule in section 6; publish blocked on failure.
- [ ] Visual editor can reproduce the example in section 4 and export byte-identical JSON.
- [ ] `GET /templates/{id}` for the section-4 example returns valid JSON the app can render.
- [ ] ETag/caching headers present on read endpoints.
- [ ] Regex/colors/fonts validated; invalid input rejected with clear errors.
- [ ] Draft/publish/archive lifecycle works end to end.

---

## 10. Glossary

- **Canvas:** the fixed-aspect drawing surface that becomes the exported PNG.
- **Field:** a user input (with validation) collected on the form page.
- **Element:** a visual item drawn on the canvas; may be static or bound to a field value.
- **Bound element:** an element whose displayed text comes from a field's value (`boundField`/`boundRow`).
- **imageSlot:** the placeholder where the end-user's uploaded photo is rendered.
- **Relative rect:** position/size expressed as `0.0–1.0` fractions of the canvas.
