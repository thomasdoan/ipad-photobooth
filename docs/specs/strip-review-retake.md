# Strip Review + Retake

## Goal
After each strip completes, show a short preview of both the video and photo with a Retake option before auto-advancing. Make the review duration configurable and add a setting to auto-advance with only a very short preview.

## UX Summary
- After each strip finishes, enter a review overlay.
- Show both video and photo in the preview.
- Default review duration: 3s.
- Auto-advance to the next strip when the timer completes.
- Provide a Retake button during review to discard the pending strip and re-capture it.
- If "Auto-advance without review" is enabled, show a very short preview (1s) and auto-advance without review controls.
- Apply the same behavior on the last strip before upload.

## Settings
- Add to Settings > Capture Settings:
  - Review Duration (seconds, default 3s, range 2–5s).
  - Auto-advance without review (toggle, default off).

## Acceptance Criteria
- Each strip shows a review overlay after capture completes.
- Review overlay displays both video and photo.
- Retake discards the pending strip and immediately re-captures it.
- Auto-advance happens after the configured duration.
- Auto-advance without review still shows a brief preview (1s) and skips review controls.
- Last strip follows the same review behavior before transitioning to upload.
