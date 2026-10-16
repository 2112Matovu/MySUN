"""The "new announcement" / "new event" alert sent to everyone (respecting
each user's notification categories) when content goes live."""

from app.services.notify import all_user_ids, notify_users


def announce_announcement(row: dict, publisher_id: str | None) -> None:
    notify_users(
        all_user_ids(exclude=[publisher_id] if publisher_id else []),
        title=f"New announcement: {row['title']}",
        body=row["description"][:140],
        type="announcement",
        related_id=row["id"],
    )


def announce_event(row: dict, publisher_id: str | None) -> None:
    notify_users(
        all_user_ids(exclude=[publisher_id] if publisher_id else []),
        title=f"New event: {row['title']}",
        body=row["venue"],
        type="event",
        related_id=row["id"],
    )


ANNOUNCERS = {"announcement": announce_announcement, "event": announce_event}
