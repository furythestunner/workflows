---
name: gemini-image-prompt
description: Turn a rough image idea into one strong English prompt to paste into the Gemini app (Nano Banana image models). Use when the user wants an image prompt, says "image prompt", "Gemini prompt", "prompt for Gemini", "make this a better prompt", "képgeneráló prompt", "írj promptot", "javítsd a promptot", pastes a weak image prompt, or wants to turn a Revit, Enscape or screenshot view into a rendered image.
metadata:
  short: "Rough idea in, one strong Gemini image prompt out."
---

# Gemini image prompt

The user is a BIM coordinator. They type a rough idea (Hungarian or English) or paste a weak prompt. You return one
finished English prompt they copy into the Gemini app. You do not make the image yourself.

Adapted from the prompting guide in jakubcurik/nano-banana (MIT, see `../THIRD-PARTY.md`), which is based on
Google's image generation guide. The plugin itself needs a paid Gemini API key; this skill needs none, because the
user pastes the prompt into the free Gemini app.

## Steps

1. Pick the mode:
   - **New image**: no picture to start from.
   - **Edit**: the user will upload a picture into Gemini (a Revit or Enscape view, a photo, a sketch).
   - **Fix**: the user already has an image in Gemini and wants one change.
2. Ask only if the answer changes the prompt a lot, at most 2 questions, multiple choice. Typical: new image or edit
   of their own view? Otherwise pick sensible defaults and name them in one line.
3. Write the prompt with the rules below.
4. Reply in the user's language, in this order:
   - The prompt in one code block (the copy button works on the phone).
   - One line: "Assumed: ..." (format, light, style you chose).
   - Two ready follow-up lines for the same Gemini chat, each in its own code block, for the most likely fixes.
   - One line only when it applies: do not upload client or NDA images on a free Gemini account.

## Rules for the prompt

- English only, even when the user writes Hungarian.
- Full sentences that describe the scene. Never a keyword list ("4k, realistic, masterpiece, trending").
- Cover: purpose, subject, setting, composition, style, light. For an edit, also what must not change.
- Talk like a photographer: shot type, lens (24 mm for architecture, 35 mm for street level, 85 mm for a detail),
  camera height (eye level, aerial, worm's-eye), depth of field.
- One concrete light source with a direction ("low evening sun from the left"). Not "cinematic lighting".
- Describe what is there, not what is not: "an empty plaza", not "no people". The one exception: "No other text."
  after text that must appear.
- No "perfect", "flawless", "beautiful". Describe materials and textures instead (glulam grain, weathered zinc,
  board-formed concrete, slight reflections on the glazing).
- Photorealism: say what kind of photo it is ("an architectural photo for a competition board"), natural colours,
  light editing, small real-life imperfections (a few people walking, cars parked, wet pavement).
- Format: the Gemini app has no size switch, so end with the format in words: "Landscape format, 16:9." It may
  still ignore it.
- Text in the image: put it in quotes, name the lettering style, add "No other text." Keep it short.
- Complex scene: give it in steps ("First, a background of ... Then, in the foreground ...").
- Length: 3 to 6 sentences. Longer is fine for an edit with many things to keep.

## Templates

**New architectural image**
"A photorealistic [shot type] of [building: storeys, structure, facade materials] in [setting]. [Light: one source,
its direction, time of day]. [People, trees, context]. Shot with a [lens] lens at [camera height], natural colours,
light editing. [Format]."

**Edit of the user's own view (Revit, Enscape, sketch, photo)**
"Using the provided image, transform this [building/interior] into a photorealistic [time of day] photo. Keep the
geometry, the window layout, the proportions and the camera angle exactly the same. Change only the materials to
[materials] and the light to [light]. [Context to add]."

**Change one thing**
"Using the provided image, change only the [element] to [new element]. Keep everything else in the image exactly
the same."

**Background for a slide or poster**
"A [style] image of [subject] placed in the [corner] of the frame, with a vast, empty [colour] area that leaves
space for text. [Light]. [Format]."

**Diagram or illustration**
"A [style, e.g. clean axonometric line drawing with soft flat colours] of [subject] showing [what]. The design uses
[colours] on a [background] background. [Format]."

## Follow-ups (same Gemini chat)

- Small changes: "That's great, but [change]. Keep everything else the same." A new prompt gives a new building.
- For a faithful edit, upload the original again with the change. Follow-ups can shift the camera and the light.
- Make 3 or 4 images per prompt (the retry button) and pick the best one: one result proves nothing.
- The model sometimes ignores composition and flips the light direction. Say it again in a follow-up.
