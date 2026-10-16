import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';

/// Publisher drafts + submission history (§4.4). Publishing is immediate —
/// there is no pre-approval gate — so this only tracks what a publisher has
/// put out and gives admins a record to remove anything that breaks the
/// terms of service (§5.1). Maps onto the moderation endpoints in §9.4-9.5
/// once the backend exists.
abstract interface class PublisherRepository {
  Future<List<PublisherSubmission>> mySubmissions();

  /// Drafts only, newest edit first (§4.4 "Draft auto-save and management").
  Future<List<PublisherSubmission>> drafts();

  /// Creates a new draft, or — when [id] matches an existing draft — updates
  /// it in place so re-saving the same draft doesn't pile up duplicates.
  Future<PublisherSubmission> saveDraft({
    String? id,
    required SubmissionType type,
    required String title,
    Map<String, dynamic>? formData,
  });

  Future<void> discardDraft(String id);

  /// Records a piece of content as published. The content itself must
  /// already be live in its own repository (e.g.
  /// `AccommodationRepository.create`) — pass its id as [contentId] so an
  /// admin's removal can delete the real thing, not just this history entry.
  /// Pass [draftId] when publishing resumes a saved draft, so that draft is
  /// converted in place instead of left behind as a duplicate.
  Future<PublisherSubmission> publish({
    String? draftId,
    required SubmissionType type,
    required String title,
    String? contentId,
  });

  /// Everything currently live, newest first — the admin review list
  /// (§5.3 Moderation Queue, adapted: review-and-remove, not approve).
  Future<List<PublisherSubmission>> recentSubmissions();

  /// Admin moderation removal, with a required reason (§5.1).
  Future<PublisherSubmission> markRemoved(String id, {required String reason});

  /// Self-service removal of one of THIS publisher's own live listings —
  /// distinct from [markRemoved] (§4.5).
  Future<PublisherSubmission> removeOwn(String id);

  /// Moves a still-scheduled announcement or event to [publishAt], or
  /// publishes it right away when [publishAt] is null.
  Future<void> reschedule(PublisherSubmission submission, DateTime? publishAt);
}

class MockPublisherRepository implements PublisherRepository {
  MockPublisherRepository({this.onRemoveContent});

  /// Deletes the underlying mock content row for a removed submission —
  /// wired in `repositories.dart` so this repo doesn't need direct
  /// references to the other Mock repos. Mirrors the real backend, where
  /// removal always deletes the content server-side (§5.1, §9.4-9.5).
  final Future<void> Function(SubmissionType type, String contentId)?
      onRemoveContent;

  static final List<PublisherSubmission> _submissions = [
    PublisherSubmission(
      id: 'sub-001',
      type: SubmissionType.announcement,
      title: 'Leave Policy',
      status: SubmissionStatus.published,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PublisherSubmission(
      id: 'sub-002',
      type: SubmissionType.announcement,
      title: 'Open Positions',
      status: SubmissionStatus.published,
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PublisherSubmission(
      id: 'sub-003',
      type: SubmissionType.announcement,
      title: 'Old Memo',
      status: SubmissionStatus.removed,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      removalReason: 'Content violated the campus communication guidelines.',
    ),
  ];

  @override
  Future<List<PublisherSubmission>> mySubmissions() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return List.unmodifiable(
      [..._submissions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<List<PublisherSubmission>> drafts() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return List.unmodifiable(
      _submissions.where((s) => s.status == SubmissionStatus.draft).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<PublisherSubmission> saveDraft({
    String? id,
    required SubmissionType type,
    required String title,
    Map<String, dynamic>? formData,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (id != null) {
      final i = _submissions.indexWhere((s) => s.id == id);
      if (i != -1) {
        final updated = _submissions[i].copyWith(
          title: title,
          formData: formData,
          updatedAt: DateTime.now(),
        );
        _submissions[i] = updated;
        return updated;
      }
    }
    final draft = PublisherSubmission(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      status: SubmissionStatus.draft,
      updatedAt: DateTime.now(),
      formData: formData,
    );
    _submissions.add(draft);
    return draft;
  }

  @override
  Future<void> discardDraft(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _submissions.removeWhere(
        (s) => s.id == id && s.status == SubmissionStatus.draft);
  }

  @override
  Future<PublisherSubmission> publish({
    String? draftId,
    required SubmissionType type,
    required String title,
    String? contentId,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (draftId != null) {
      final i = _submissions.indexWhere((s) => s.id == draftId);
      if (i != -1) {
        final updated = PublisherSubmission(
          id: draftId,
          type: type,
          title: title,
          status: SubmissionStatus.published,
          updatedAt: DateTime.now(),
          contentId: contentId,
        );
        _submissions[i] = updated;
        return updated;
      }
    }
    final submission = PublisherSubmission(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      status: SubmissionStatus.published,
      updatedAt: DateTime.now(),
      contentId: contentId,
    );
    _submissions.add(submission);
    return submission;
  }

  @override
  Future<List<PublisherSubmission>> recentSubmissions() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return List.unmodifiable(
      _submissions.where((s) => s.status == SubmissionStatus.published).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<PublisherSubmission> markRemoved(String id, {required String reason}) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final i = _submissions.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Submission $id not found');
    final submission = _submissions[i];
    final contentId = submission.contentId;
    if (contentId != null && onRemoveContent != null) {
      await onRemoveContent!(submission.type, contentId);
    }
    final updated = submission.copyWith(
      status: SubmissionStatus.removed,
      updatedAt: DateTime.now(),
      removalReason: reason,
    );
    _submissions[i] = updated;
    return updated;
  }

  @override
  Future<PublisherSubmission> removeOwn(String id) =>
      markRemoved(id, reason: 'Removed by the publisher.');

  @override
  Future<void> reschedule(
      PublisherSubmission submission, DateTime? publishAt) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final i = _submissions.indexWhere((s) => s.id == submission.id);
    if (i < 0) return;
    _submissions[i] = publishAt == null
        ? _submissions[i].copyWith(
            status: SubmissionStatus.published, updatedAt: DateTime.now())
        : _submissions[i]
            .copyWith(publishAt: publishAt, updatedAt: DateTime.now());
  }
}

class HttpPublisherRepository implements PublisherRepository {
  HttpPublisherRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<PublisherSubmission>> mySubmissions() async {
    try {
      final res = await _dio.get('/publisher/submissions');
      return (res.data as List)
          .map((e) => PublisherSubmission.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<PublisherSubmission>> drafts() async {
    try {
      final res = await _dio.get('/publisher/drafts');
      return (res.data as List)
          .map((e) => PublisherSubmission.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<PublisherSubmission> saveDraft({
    String? id,
    required SubmissionType type,
    required String title,
    Map<String, dynamic>? formData,
  }) async {
    try {
      final res = await _dio.post('/publisher/drafts', data: {
        'id': id,
        'type': type.name,
        'title': title,
        'form_data': formData,
      });
      return PublisherSubmission.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> discardDraft(String id) async {
    try {
      await _dio.delete('/publisher/drafts/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<PublisherSubmission> publish({
    String? draftId,
    required SubmissionType type,
    required String title,
    String? contentId,
  }) async {
    // The corresponding content endpoint (e.g. POST /accommodation) already
    // created the live submission row server-side. If this resumed a
    // draft, just clean up the now-stale draft — best effort, since the
    // content itself is already live regardless of whether this succeeds.
    if (draftId != null) {
      try {
        await _dio.delete('/publisher/drafts/$draftId');
      } catch (_) {
        // Ignore — nothing more to do client-side either way.
      }
    }
    return PublisherSubmission(
      id: contentId ?? draftId ?? '',
      type: type,
      title: title,
      status: SubmissionStatus.published,
      updatedAt: DateTime.now(),
      contentId: contentId,
    );
  }

  @override
  Future<List<PublisherSubmission>> recentSubmissions() async {
    try {
      final res = await _dio.get('/admin/moderation');
      return (res.data as List)
          .map((e) => PublisherSubmission.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<PublisherSubmission> markRemoved(String id, {required String reason}) async {
    try {
      final res = await _dio.post(
        '/admin/moderation/$id/remove',
        data: {'reason': reason},
      );
      return PublisherSubmission.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<PublisherSubmission> removeOwn(String id) async {
    try {
      final res = await _dio.post('/publisher/submissions/$id/remove');
      return PublisherSubmission.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> reschedule(
      PublisherSubmission submission, DateTime? publishAt) async {
    final contentId = submission.contentId;
    final collection = switch (submission.type) {
      SubmissionType.announcement => 'announcements',
      SubmissionType.event => 'events',
      _ => null,
    };
    if (contentId == null || collection == null) {
      throw const ApiException('Only announcements and events can be scheduled');
    }
    try {
      await _dio.patch('/$collection/$contentId/schedule',
          data: {'publish_at': publishAt?.toUtc().toIso8601String()});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
