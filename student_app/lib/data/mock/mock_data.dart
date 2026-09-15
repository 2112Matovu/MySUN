import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/app_notification.dart';
import 'package:mysun_app/data/models/bus_schedule.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/data/models/transport_provider.dart';
import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';

/// Seed content for the app while it runs without a backend.
///
/// Dates are computed relative to "now" on each access so the feed, countdowns
/// and "next bus" cards always look live in a demo.
abstract final class MockData {
  static DateTime get _now => DateTime.now();
  static DateTime _daysAgo(int d, {int h = 9, int m = 0}) =>
      DateTime(_now.year, _now.month, _now.day, h, m)
          .subtract(Duration(days: d));
  static DateTime _daysAhead(int d, {int h = 14, int m = 0}) =>
      DateTime(_now.year, _now.month, _now.day, h, m).add(Duration(days: d));
  static DateTime _hoursAgo(int h) => _now.subtract(Duration(hours: h));

  static UserProfile get currentUser => const UserProfile(
        id: 'usr-001',
        name: 'Amos Ekiring',
        email: 'amos.ekiring@stud.sorotiu.ac.ug',
        studentId: 'SU/2023/BSC/0142',
        faculty: 'Faculty of Science & Education',
        program: 'BSc. Computer Science',
        role: UserRole.student,
      );

  static List<Announcement> get announcements => [
        Announcement(
          id: 'ann-001',
          title: 'End of Semester Examinations Timetable Released',
          description:
              'The examinations timetable for Semester One 2025/2026 is now '
              'available on the university portal and notice boards. Exams begin '
              'Monday and run for three weeks. Students with clashes should '
              'report to the Academic Registrar\'s office by Friday. Bring your '
              'student ID and examination permit to every paper.',
          category: 'Academic',
          publisherName: 'Academic Registrar',
          publishedAt: _hoursAgo(3),
          isImportant: true,
          imageUrl: 'https://picsum.photos/seed/mysun-exams/800/400',
        ),
        Announcement(
          id: 'ann-002',
          title: 'Library Extended Hours During Exam Period',
          description:
              'The Main Library will open from 7:00 AM to 12:00 midnight for '
              'the duration of the examination period. The 24-hour reading room '
              'on the ground floor remains open throughout. Please carry your '
              'library card for after-hours access.',
          category: 'Academic',
          publisherName: 'University Librarian',
          publishedAt: _hoursAgo(20),
          imageUrl: 'https://picsum.photos/seed/mysun-library/800/400',
        ),
        Announcement(
          id: 'ann-003',
          title: 'Guild Elections — Nomination of Candidates',
          description:
              'Nominations for the 2025/2026 Students\' Guild are open. Pick '
              'nomination forms from the Dean of Students office. Nominees must '
              'have a CGPA of at least 3.0 and no pending disciplinary cases. '
              'Campaigns start next week; polling day is two weeks from Friday.',
          category: 'Administration',
          publisherName: 'Dean of Students',
          publishedAt: _daysAgo(1, h: 11),
        ),
        Announcement(
          id: 'ann-004',
          title: 'Free Wi-Fi Upgrade Across Campus Hostels',
          description:
              'ICT Directorate has completed the hostel network upgrade. All '
              'blocks now have fibre-backed Wi-Fi. Connect to "SU-Student" and '
              'sign in with your student portal credentials. Report dead spots '
              'to the ICT helpdesk in the Administration block.',
          category: 'Administration',
          publisherName: 'ICT Directorate',
          publishedAt: _daysAgo(2, h: 15),
          imageUrl: 'https://picsum.photos/seed/mysun-wifi/800/400',
        ),
        Announcement(
          id: 'ann-005',
          title: 'Inter-Faculty Football Tournament Kicks Off Saturday',
          description:
              'The annual inter-faculty football tournament begins this '
              'Saturday at the University Grounds. Science & Education faces '
              'Management Sciences in the opening fixture at 3:00 PM. Come and '
              'support your faculty. Entry is free for all students.',
          category: 'Sports',
          publisherName: 'Sports Department',
          publishedAt: _daysAgo(2, h: 9),
          imageUrl: 'https://picsum.photos/seed/mysun-football/800/400',
        ),
        Announcement(
          id: 'ann-006',
          title: 'Campus Clean-Up Day — Volunteers Needed',
          description:
              'Join the Environmental Club this Sunday morning for a campus-wide '
              'clean-up. Meet at the main gate at 8:00 AM. Gloves and bags '
              'provided. Volunteers get a certificate of participation and free '
              'breakfast afterwards.',
          category: 'Clubs',
          publisherName: 'Environmental Club',
          publishedAt: _daysAgo(3, h: 13),
        ),
        Announcement(
          id: 'ann-007',
          title: 'Adjusted Campus Shuttle Route via Arapai',
          description:
              'Due to roadworks on the Soroti–Arapai road, the afternoon '
              'shuttle will divert through the Pamba stage until further notice. '
              'Expect an extra 10 minutes travel time. Morning departures are '
              'unaffected.',
          category: 'Transport',
          publisherName: 'Transport Office',
          publishedAt: _daysAgo(4, h: 8),
        ),
        Announcement(
          id: 'ann-008',
          title: 'Cultural Gala Night — Save the Date',
          description:
              'The Students\' Guild presents Cultural Gala Night at the main '
              'auditorium in two weeks. Expect traditional dance, poetry, a '
              'fashion runway and food stalls from every region. Tickets go on '
              'sale next week at the Guild office.',
          category: 'Social',
          publisherName: 'Students\' Guild',
          publishedAt: _daysAgo(5, h: 17),
          imageUrl: 'https://picsum.photos/seed/mysun-gala/800/400',
        ),
        Announcement(
          id: 'ann-009',
          title: 'Tuition Payment Deadline Extended',
          description:
              'The Finance Department has extended the tuition payment deadline '
              'by one week. Students who have paid at least 60% may sit '
              'examinations. Clear balances through the bank or mobile money '
              'using your registration number as reference.',
          category: 'Administration',
          publisherName: 'Finance Department',
          publishedAt: _daysAgo(6, h: 10),
          isImportant: true,
        ),
        Announcement(
          id: 'ann-010',
          title: 'Research Methods Workshop for Finalists',
          description:
              'The School of Graduate Studies is running a two-day research '
              'methods and academic writing workshop for final-year students. '
              'Sessions cover proposal structure, referencing and plagiarism '
              'checks. Register with your department coordinator.',
          category: 'Academic',
          publisherName: 'School of Graduate Studies',
          publishedAt: _daysAgo(7, h: 12),
        ),
      ];

  static List<Event> get events => [
        Event(
          id: 'evt-001',
          title: 'Career Fair 2026',
          description:
              'Meet recruiters from banks, telecoms, NGOs and government '
              'agencies. Bring printed copies of your CV. There will be CV '
              'clinics, mock interviews and on-the-spot internship offers.',
          category: 'Academic',
          organizerName: 'Careers & Counselling Unit',
          dateTime: _daysAhead(1, h: 9),
          endDateTime: _daysAhead(1, h: 16),
          venue: 'University Main Hall',
          capacity: 500,
          registeredCount: 213,
          isFeatured: true,
          imageUrl: 'https://picsum.photos/seed/mysun-career/800/400',
        ),
        Event(
          id: 'evt-002',
          title: 'Hackathon: Build for Teso',
          description:
              'A 24-hour hackathon challenging students to prototype digital '
              'solutions for local agriculture, health and education. Teams of '
              'up to four. Laptops, mentors and meals provided. Top three teams '
              'win cash prizes and incubation support.',
          category: 'Workshops',
          organizerName: 'Department of Computer Science',
          dateTime: _daysAhead(3, h: 10),
          endDateTime: _daysAhead(4, h: 10),
          venue: 'ICT Lab 2, Science Block',
          capacity: 80,
          registeredCount: 64,
          isFeatured: true,
          imageUrl: 'https://picsum.photos/seed/mysun-hack/800/400',
        ),
        Event(
          id: 'evt-003',
          title: 'Inter-Faculty Football: Science vs Management',
          description:
              'Opening fixture of the inter-faculty tournament. Come early for '
              'a good seat. Faculty jerseys encouraged.',
          category: 'Sports',
          organizerName: 'Sports Department',
          dateTime: _daysAhead(2, h: 15),
          endDateTime: _daysAhead(2, h: 17),
          venue: 'University Sports Grounds',
          registeredCount: 0,
          imageUrl: 'https://picsum.photos/seed/mysun-match/800/400',
        ),
        Event(
          id: 'evt-004',
          title: 'Guild Presidential Debate',
          description:
              'Candidates for Guild President face questions on welfare, '
              'academics and campus infrastructure. Moderated by the Debating '
              'Society. Submit your questions at the door.',
          category: 'Social',
          organizerName: 'Debating Society',
          dateTime: _daysAhead(5, h: 17),
          endDateTime: _daysAhead(5, h: 19),
          venue: 'Auditorium',
          capacity: 400,
          registeredCount: 88,
        ),
        Event(
          id: 'evt-005',
          title: 'Entrepreneurship Bootcamp',
          description:
              'Three evening sessions on turning an idea into a registered '
              'business: lean canvas, pricing, and pitching to investors. '
              'Facilitated by alumni founders.',
          category: 'Workshops',
          organizerName: 'Business Incubation Centre',
          dateTime: _daysAhead(6, h: 16, m: 30),
          endDateTime: _daysAhead(6, h: 19),
          venue: 'Management Sciences Seminar Room',
          capacity: 60,
          registeredCount: 41,
          imageUrl: 'https://picsum.photos/seed/mysun-boot/800/400',
        ),
        Event(
          id: 'evt-006',
          title: 'Blood Donation Drive',
          description:
              'Uganda Blood Transfusion Service is on campus for a one-day '
              'donation drive. Donors receive a snack and a health check. Eat '
              'well and hydrate before donating.',
          category: 'Social',
          organizerName: 'Red Cross Club',
          dateTime: _daysAhead(4, h: 9),
          endDateTime: _daysAhead(4, h: 15),
          venue: 'University Clinic Forecourt',
        ),
        Event(
          id: 'evt-007',
          title: 'Christian Union Worship Night',
          description:
              'An evening of worship, testimony and fellowship. All are '
              'welcome. Bring a friend.',
          category: 'Clubs',
          organizerName: 'Christian Union',
          dateTime: _daysAhead(2, h: 18, m: 30),
          endDateTime: _daysAhead(2, h: 21),
          venue: 'Lecture Theatre 1',
        ),
        Event(
          id: 'evt-008',
          title: 'Alumni Homecoming Lecture',
          description:
              'A distinguished alumnus in public health delivers this year\'s '
              'homecoming lecture, followed by networking tea. Open to all '
              'students and staff.',
          category: 'Academic',
          organizerName: 'Alumni Relations Office',
          dateTime: _daysAhead(8, h: 11),
          endDateTime: _daysAhead(8, h: 13),
          venue: 'University Main Hall',
          capacity: 300,
          registeredCount: 52,
          imageUrl: 'https://picsum.photos/seed/mysun-alumni/800/400',
        ),
        Event(
          id: 'evt-009',
          title: 'Freshers\' Orientation Recap',
          description:
              'A recorded recap session for first-years who missed orientation '
              'week: portal use, library membership, hostel rules and support '
              'services.',
          category: 'Academic',
          organizerName: 'Dean of Students',
          dateTime: _daysAgo(2, h: 10),
          endDateTime: _daysAgo(2, h: 12),
          venue: 'Auditorium',
        ),
      ];

  // Transport is Boda-only for now (spec §6 services framework — taxi/bus/
  // matatu can come back as separate service types later).
  static List<TransportProvider> get transportProviders => [
        const TransportProvider(
          id: 'trp-002',
          name: 'Teso Riders Boda Stage (Main Gate)',
          phoneNumber: '+256 772 345 678',
          serviceType: 'boda',
          contactPerson: 'Stage Chairperson: Okello',
          isVerified: true,
          rating: 4.3,
          ratingCount: 96,
          operatingHours: '5:30 AM - 11:00 PM',
          serviceAreas: ['Main Gate', 'Soroti Town', 'Hospital', 'Bus Park'],
        ),
        const TransportProvider(
          id: 'trp-005',
          name: 'Night Owl Boda (Verified Riders)',
          phoneNumber: '+256 781 640 320',
          serviceType: 'boda',
          contactPerson: 'Night coordinator',
          isVerified: true,
          rating: 4.1,
          ratingCount: 39,
          operatingHours: '8:00 PM - 5:00 AM',
          serviceAreas: ['Main Gate', 'Hostels', 'Soroti Town'],
        ),
      ];

  static List<BusSchedule> get busSchedules => [
        const BusSchedule(
          id: 'bus-001',
          routeName: 'Morning Express',
          departurePoint: 'Main Campus Gate',
          destination: 'Soroti Town (Independence Square)',
          departureTime: '07:00',
          estimatedDurationMinutes: 25,
          operatingDays: 'Mon-Fri',
        ),
        const BusSchedule(
          id: 'bus-002',
          routeName: 'Arapai Link',
          departurePoint: 'Main Campus Gate',
          destination: 'Arapai Campus',
          departureTime: '08:00',
          estimatedDurationMinutes: 20,
          operatingDays: 'Mon-Fri',
        ),
        const BusSchedule(
          id: 'bus-003',
          routeName: 'Midday Shuttle',
          departurePoint: 'Soroti Town (Independence Square)',
          destination: 'Main Campus Gate',
          departureTime: '13:00',
          estimatedDurationMinutes: 25,
          operatingDays: 'Daily',
        ),
        const BusSchedule(
          id: 'bus-004',
          routeName: 'Arapai Link',
          departurePoint: 'Arapai Campus',
          destination: 'Main Campus Gate',
          departureTime: '17:00',
          estimatedDurationMinutes: 20,
          operatingDays: 'Mon-Fri',
        ),
        const BusSchedule(
          id: 'bus-005',
          routeName: 'Evening Express',
          departurePoint: 'Main Campus Gate',
          destination: 'Soroti Town (Bus Park)',
          departureTime: '18:30',
          estimatedDurationMinutes: 30,
          operatingDays: 'Daily',
        ),
        const BusSchedule(
          id: 'bus-006',
          routeName: 'Weekend Market Run',
          departurePoint: 'Main Campus Gate',
          destination: 'Soroti Central Market',
          departureTime: '10:00',
          estimatedDurationMinutes: 25,
          operatingDays: 'Weekend',
        ),
        const BusSchedule(
          id: 'bus-007',
          routeName: 'Library Late Shuttle',
          departurePoint: 'Main Library',
          destination: 'Hostels & Main Gate',
          departureTime: '22:30',
          estimatedDurationMinutes: 10,
          operatingDays: 'Mon-Sat',
          notes: 'Runs only during the examination period.',
        ),
        const BusSchedule(
          id: 'bus-008',
          routeName: 'Church Run',
          departurePoint: 'Main Campus Gate',
          destination: 'Soroti Town Churches',
          departureTime: '07:30',
          estimatedDurationMinutes: 25,
          operatingDays: 'Sunday',
          status: 'suspended',
          notes: 'Suspended this week due to vehicle service.',
        ),
      ];

  static List<AppNotification> get notifications => [
        AppNotification(
          id: 'ntf-001',
          title: 'Exam timetable is out',
          body:
              'End of Semester Examinations Timetable Released. Tap to view the '
              'full announcement.',
          type: 'announcement',
          relatedId: 'ann-001',
          createdAt: _hoursAgo(3),
        ),
        AppNotification(
          id: 'ntf-002',
          title: 'Career Fair 2026 starts tomorrow',
          body: 'Reminder: Career Fair 2026 at the University Main Hall, 9:00 AM.',
          type: 'reminder',
          relatedId: 'evt-001',
          createdAt: _hoursAgo(6),
        ),
        AppNotification(
          id: 'ntf-003',
          title: 'Next bus in 20 minutes',
          body: 'Morning Express departs Main Campus Gate for Soroti Town.',
          type: 'transport',
          relatedId: 'bus-001',
          createdAt: _hoursAgo(9),
          isRead: true,
        ),
        AppNotification(
          id: 'ntf-004',
          title: 'New event: Hackathon: Build for Teso',
          body: 'Registration is open. 64 of 80 places taken.',
          type: 'event',
          relatedId: 'evt-002',
          createdAt: _hoursAgo(22),
        ),
        AppNotification(
          id: 'ntf-005',
          title: 'Tuition deadline extended',
          body: 'You now have one extra week to clear at least 60%.',
          type: 'announcement',
          relatedId: 'ann-009',
          createdAt: _daysAgo(1, h: 10),
          isRead: true,
        ),
        AppNotification(
          id: 'ntf-006',
          title: 'Welcome to MySun',
          body:
              'Your campus companion. Follow categories you care about in '
              'Settings to tailor your feed.',
          type: 'system',
          createdAt: _daysAgo(3, h: 8),
          isRead: true,
        ),
      ];
}
