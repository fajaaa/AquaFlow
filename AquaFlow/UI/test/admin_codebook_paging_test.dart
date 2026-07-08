// Covers the shared step-back-a-page-after-delete rule used by all three
// AdminCodebookScreen levels (Gradovi/Općine/Naselja) so the behaviour is
// verified once instead of trusting three separate call sites.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaflow_desktop/admin/screens/admin_codebook_screen.dart';

void main() {
  group('shouldStepBackAfterDelete', () {
    test('steps back when the last row on a non-first page is deleted', () {
      expect(
        shouldStepBackAfterDelete(itemsOnPage: 1, page: 2),
        isTrue,
      );
    });

    test('stays put when the last row on the first page is deleted', () {
      expect(
        shouldStepBackAfterDelete(itemsOnPage: 1, page: 1),
        isFalse,
      );
    });

    test('stays put when other rows remain on the page', () {
      expect(
        shouldStepBackAfterDelete(itemsOnPage: 2, page: 3),
        isFalse,
      );
    });

    test('stays put when the page is already empty', () {
      expect(
        shouldStepBackAfterDelete(itemsOnPage: 0, page: 2),
        isFalse,
      );
    });
  });
}
