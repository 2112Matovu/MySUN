"""Re-runnable seed script: demo accounts + a small sample content set, so
the app isn't empty on first run against a fresh Supabase project.

Run from backend/ with the venv active:
    python scripts/seed_demo_data.py
"""

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.supabase_client import get_supabase_admin  # noqa: E402

DEMO_ACCOUNTS = [
    {
        "email": "student@sun.ac.ug",
        "password": "student123",
        "name": "Amos Ekiring",
        "role": "student",
        "faculty": "Faculty of Science & Education",
        "program": "BSc. Computer Science",
        "student_id": "SU/2023/BSC/0142",
    },
    {
        "email": "publisher@sun.ac.ug",
        "password": "publisher123",
        "name": "Sarah Akena",
        "role": "publisher",
        "faculty": "HR Department",
    },
    {
        "email": "admin@sun.ac.ug",
        "password": "admin123",
        "name": "Grace Amongin",
        "role": "admin",
    },
]


def _now():
    return datetime.now(timezone.utc)


def ensure_accounts(admin) -> dict[str, str]:
    """Creates the three demo accounts (confirmed, no email step) if they
    don't already exist, and makes sure their role is set correctly.
    Returns {email: user_id}."""
    ids: dict[str, str] = {}
    for acct in DEMO_ACCOUNTS:
        existing = (
            admin.table("profiles")
            .select("id")
            .eq("email", acct["email"])
            .maybe_single()
            .execute()
        )
        if existing and existing.data:
            user_id = existing.data["id"]
            print(f"exists:  {acct['email']} ({user_id})")
        else:
            result = admin.auth.admin.create_user(
                {
                    "email": acct["email"],
                    "password": acct["password"],
                    "email_confirm": True,
                    "user_metadata": {
                        "name": acct["name"],
                        "faculty": acct.get("faculty"),
                        "program": acct.get("program"),
                    },
                }
            )
            user_id = result.user.id
            print(f"created: {acct['email']} ({user_id})")
        admin.table("profiles").update(
            {"role": acct["role"], "student_id": acct.get("student_id")}
        ).eq("id", user_id).execute()
        ids[acct["email"]] = user_id
    return ids


def seed_content(admin, publisher_name: str) -> None:
    if admin.table("announcements").select("id").limit(1).execute().data:
        print("content already seeded, skipping")
        return

    announcements = [
        {
            "title": "End of Semester Examinations Timetable Released",
            "description": (
                "The examinations timetable for this semester is now available "
                "on the university portal and notice boards. Exams begin Monday "
                "and run for three weeks."
            ),
            "category": "Academic",
            "publisher_name": "Academic Registrar",
            "published_at": (_now() - timedelta(hours=3)).isoformat(),
            "is_important": True,
            "image_url": "https://picsum.photos/seed/mysun-exams/800/400",
        },
        {
            "title": "Library Extended Hours During Exam Period",
            "description": (
                "The Main Library will open from 7:00 AM to 12:00 midnight for "
                "the duration of the examination period."
            ),
            "category": "Academic",
            "publisher_name": "University Librarian",
            "published_at": (_now() - timedelta(hours=20)).isoformat(),
            "is_important": False,
            "image_url": "https://picsum.photos/seed/mysun-library/800/400",
        },
        {
            "title": "Guild Elections — Nomination of Candidates",
            "description": (
                "Nominations for the Students' Guild are open. Pick nomination "
                "forms from the Dean of Students office."
            ),
            "category": "Administration",
            "publisher_name": "Dean of Students",
            "published_at": (_now() - timedelta(days=1)).isoformat(),
            "is_important": False,
        },
        {
            "title": "Free Wi-Fi Upgrade Across Campus Hostels",
            "description": (
                "ICT Directorate has completed the hostel network upgrade. "
                "Connect to \"SU-Student\" with your student portal credentials."
            ),
            "category": "Administration",
            "publisher_name": "ICT Directorate",
            "published_at": (_now() - timedelta(days=2)).isoformat(),
            "is_important": False,
            "image_url": "https://picsum.photos/seed/mysun-wifi/800/400",
        },
    ]
    admin.table("announcements").insert(announcements).execute()
    print(f"seeded {len(announcements)} announcements")

    events = [
        {
            "title": "Career Fair 2026",
            "description": (
                "Meet recruiters from banks, telecoms, NGOs and government "
                "agencies. Bring printed copies of your CV."
            ),
            "category": "Academic",
            "organizer_name": "Careers & Counselling Unit",
            "date_time": (_now() + timedelta(days=1, hours=9)).isoformat(),
            "end_date_time": (_now() + timedelta(days=1, hours=16)).isoformat(),
            "venue": "University Main Hall",
            "capacity": 500,
            "registered_count": 213,
            "is_featured": True,
            "image_url": "https://picsum.photos/seed/mysun-career/800/400",
        },
        {
            "title": "Hackathon: Build for Teso",
            "description": (
                "A 24-hour hackathon challenging students to prototype digital "
                "solutions for local agriculture, health and education."
            ),
            "category": "Workshops",
            "organizer_name": "Department of Computer Science",
            "date_time": (_now() + timedelta(days=3, hours=10)).isoformat(),
            "end_date_time": (_now() + timedelta(days=4, hours=10)).isoformat(),
            "venue": "ICT Lab 2, Science Block",
            "capacity": 80,
            "registered_count": 64,
            "is_featured": True,
            "image_url": "https://picsum.photos/seed/mysun-hack/800/400",
        },
        {
            "title": "Inter-Faculty Football: Science vs Management",
            "description": "Opening fixture of the inter-faculty tournament.",
            "category": "Sports",
            "organizer_name": "Sports Department",
            "date_time": (_now() + timedelta(days=2, hours=15)).isoformat(),
            "end_date_time": (_now() + timedelta(days=2, hours=17)).isoformat(),
            "venue": "University Sports Grounds",
            "registered_count": 0,
            "is_featured": False,
            "image_url": "https://picsum.photos/seed/mysun-match/800/400",
        },
    ]
    admin.table("events").insert(events).execute()
    print(f"seeded {len(events)} events")

    accommodation = [
        {
            "name": "Green Valley Hostel",
            "type": "hostel",
            "location": "5 min walk from Main Gate",
            "price": 900000,
            "is_gazetted": True,
            "room_sharing": "both",
            "contact_phone": "+256 700 111 222",
            "image_urls": [
                "https://picsum.photos/seed/mysun-hostel-1/800/500",
                "https://picsum.photos/seed/mysun-hostel-1b/800/500",
            ],
            "description": (
                "University-registered hostel with 24/7 security, water and "
                "power backup."
            ),
            "publisher_name": publisher_name,
        },
        {
            "name": "Sunrise Self-Contained Rentals",
            "type": "rental",
            "location": "Soroti Town, near Independence Square",
            "price": 400000,
            "is_gazetted": False,
            "room_sharing": "private",
            "contact_phone": "+256 753 555 666",
            "image_urls": ["https://picsum.photos/seed/mysun-rental-1/800/500"],
            "description": "Independent self-contained single rooms.",
            "publisher_name": publisher_name,
        },
    ]
    admin.table("accommodation_listings").insert(accommodation).execute()
    print(f"seeded {len(accommodation)} accommodation listings")

    transport = [
        {
            "name": "Teso Riders Boda Stage (Main Gate)",
            "phone_number": "+256 772 345 678",
            "service_type": "boda",
            "contact_person": "Stage Chairperson: Okello",
            "is_verified": True,
            "rating": 4.3,
            "rating_count": 96,
            "operating_hours": "5:30 AM - 11:00 PM",
            "service_areas": ["Main Gate", "Soroti Town", "Hospital", "Bus Park"],
        },
        {
            "name": "Night Owl Boda (Verified Riders)",
            "phone_number": "+256 781 640 320",
            "service_type": "boda",
            "contact_person": "Night coordinator",
            "is_verified": True,
            "rating": 4.1,
            "rating_count": 39,
            "operating_hours": "8:00 PM - 5:00 AM",
            "service_areas": ["Main Gate", "Hostels", "Soroti Town"],
        },
    ]
    admin.table("transport_providers").insert(transport).execute()
    print(f"seeded {len(transport)} transport providers")

    bus_schedules = [
        {
            "route_name": "Morning Express",
            "departure_point": "Main Campus Gate",
            "destination": "Soroti Town (Independence Square)",
            "departure_time": "07:00",
            "estimated_duration_minutes": 25,
            "operating_days": "Mon-Fri",
        },
        {
            "route_name": "Midday Shuttle",
            "departure_point": "Soroti Town (Independence Square)",
            "destination": "Main Campus Gate",
            "departure_time": "13:00",
            "estimated_duration_minutes": 25,
            "operating_days": "Daily",
        },
        {
            "route_name": "Evening Express",
            "departure_point": "Main Campus Gate",
            "destination": "Soroti Town (Bus Park)",
            "departure_time": "18:30",
            "estimated_duration_minutes": 30,
            "operating_days": "Daily",
        },
    ]
    admin.table("bus_schedules").insert(bus_schedules).execute()
    print(f"seeded {len(bus_schedules)} bus schedules")


def main():
    admin = get_supabase_admin()
    ids = ensure_accounts(admin)
    seed_content(admin, publisher_name="Sarah Akena (HR Department)")

    student_id = ids["student@sun.ac.ug"]
    if not admin.table("notifications").select("id").eq("user_id", student_id).execute().data:
        admin.table("notifications").insert(
            [
                {
                    "user_id": student_id,
                    "title": "Welcome to MySun",
                    "body": "Your campus companion. Follow categories you care about in Settings.",
                    "type": "system",
                    "created_at": (_now() - timedelta(days=1)).isoformat(),
                },
            ]
        ).execute()
        print("seeded 1 notification for the demo student")

    print("\nDone. Demo accounts:")
    for acct in DEMO_ACCOUNTS:
        print(f"  {acct['email']} / {acct['password']}  ({acct['role']})")


if __name__ == "__main__":
    main()
