from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import require_publisher
from app.schemas.publisher import DraftSave, PublisherPerformance, PublisherSubmission
from app.schemas.user import UserProfile
from app.services.publisher_service import compute_performance, engagement_stats, remove_content, submissions_repo

router = APIRouter(prefix="/publisher", tags=["publisher"])


@router.get("/submissions", response_model=list[PublisherSubmission])
def my_submissions(user: UserProfile = Depends(require_publisher)) -> list[dict]:
    return submissions_repo.list(order_by="updated_at", desc=True, publisher_id=user.id)


@router.get("/drafts", response_model=list[PublisherSubmission])
def my_drafts(user: UserProfile = Depends(require_publisher)) -> list[dict]:
    return submissions_repo.list(
        order_by="updated_at", desc=True, publisher_id=user.id, status="draft"
    )


@router.post("/drafts", response_model=PublisherSubmission)
def save_draft(body: DraftSave, user: UserProfile = Depends(require_publisher)) -> dict:
    """Creates a new draft, or — when [id] matches one of this publisher's
    own drafts — updates it in place so re-saving doesn't pile up
    duplicates (§4.4 "Draft auto-save and management")."""
    payload = {"type": body.type, "title": body.title, "form_data": body.form_data}
    if body.id:
        existing = submissions_repo.list(id=body.id, publisher_id=user.id, status="draft")
        if existing:
            return submissions_repo.update(body.id, payload)
    payload["publisher_id"] = user.id
    payload["status"] = "draft"
    return submissions_repo.create(payload)


@router.delete("/drafts/{id}", status_code=204)
def discard_draft(id: str, user: UserProfile = Depends(require_publisher)) -> None:
    existing = submissions_repo.list(id=id, publisher_id=user.id, status="draft")
    if not existing:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Draft not found")
    submissions_repo.delete(id)


@router.post("/submissions/{submission_id}/remove", response_model=PublisherSubmission)
def remove_own_submission(
    submission_id: str, user: UserProfile = Depends(require_publisher)
) -> dict:
    """Self-service removal of one of THIS publisher's own live listings
    (§4.5) — distinct from admin moderation
    (POST /admin/moderation/{id}/remove), which takes an admin-supplied
    reason and works on anyone's content."""
    submission = submissions_repo.get(submission_id)
    if submission["publisher_id"] != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your submission")
    return remove_content(submission, "Removed by the publisher.")


@router.get("/performance", response_model=PublisherPerformance)
def my_performance(user: UserProfile = Depends(require_publisher)) -> dict:
    submissions = submissions_repo.list(publisher_id=user.id)
    views, interactions = engagement_stats(submissions)
    return compute_performance(submissions, views, interactions)
