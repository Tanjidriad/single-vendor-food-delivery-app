// Feature: admin-panel-redesign
//
// Property-based tests for the WDataTable pure logic classes
// (WTableSortState and WTablePagination).
//
// These tests validate universal correctness properties from the design
// document. No third-party PBT package is available in this project, so we use
// randomized / exhaustive generation with dart:math as the property engine,
// matching the convention established in
// test/core/theme/tokens_property_test.dart and
// test/core/widgets/w_status_badge_property_test.dart.
//
// - Property 4: Sort column toggle is an involution
// - Property 5: Pagination navigation button state correctness

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/widgets/w_data_table.dart';

void main() {
  // The design document specifies a minimum of 100 iterations per property;
  // we exceed that comfortably.
  const int iterations = 1000;
  final random = Random(20240219);

  group('Property 4: Sort column toggle is an involution', () {
    // Validates: Requirements 3.7
    //
    // For any sortable column in a WDataTable, tapping the column header twice
    // SHALL return the sort state to its original direction
    // (ascending -> descending -> ascending).
    //
    // WTableSortState.toggle is the pure function under test:
    //   - Tapping the active column flips `ascending`.
    //   - Tapping a different column activates it ascending.
    // Therefore toggling the *same* column twice is an involution on the
    // `ascending` flag while keeping that column active.

    test('toggling the active column twice restores the original direction',
        () {
      for (var i = 0; i < iterations; i++) {
        // Random initial active column and direction.
        final columnIndex = random.nextInt(10); // 0..9
        final ascending = random.nextBool();
        final initial =
            WTableSortState(columnIndex: columnIndex, ascending: ascending);

        // Tap the same (active) column twice.
        final once = initial.toggle(columnIndex);
        final twice = once.toggle(columnIndex);

        // The single toggle must flip the direction and keep the column.
        expect(once.columnIndex, columnIndex,
            reason: 'a single toggle keeps the same column active');
        expect(once.ascending, !ascending,
            reason: 'a single toggle on the active column flips direction');

        // Toggling twice is an involution: back to the original state.
        expect(twice, initial,
            reason: 'toggling the active column twice is an involution');
        expect(twice.columnIndex, columnIndex);
        expect(twice.ascending, ascending);
      }
    });

    test(
        'tapping a different column activates it ascending, and tapping it '
        'twice more is then an involution', () {
      for (var i = 0; i < iterations; i++) {
        final activeColumn = random.nextInt(10);
        final ascending = random.nextBool();
        final initial =
            WTableSortState(columnIndex: activeColumn, ascending: ascending);

        // Choose a different column index.
        var otherColumn = random.nextInt(10);
        if (otherColumn == activeColumn) {
          otherColumn = (otherColumn + 1) % 10;
        }

        // Tapping a different column activates it in ascending order.
        final activated = initial.toggle(otherColumn);
        expect(activated.columnIndex, otherColumn,
            reason: 'tapping a different column activates that column');
        expect(activated.ascending, isTrue,
            reason: 'a newly activated column starts ascending');

        // From there, tapping the (now active) other column twice is an
        // involution.
        final twice = activated.toggle(otherColumn).toggle(otherColumn);
        expect(twice, activated,
            reason: 'two toggles on the now-active column is an involution');
      }
    });

    test('toggling the active column an even number of times is identity', () {
      for (var i = 0; i < iterations; i++) {
        final columnIndex = random.nextInt(10);
        final ascending = random.nextBool();
        final initial =
            WTableSortState(columnIndex: columnIndex, ascending: ascending);

        // Apply 2 * k toggles for a random k.
        final pairs = random.nextInt(6); // 0..5 -> 0,2,4,...,10 toggles
        var state = initial;
        for (var t = 0; t < pairs * 2; t++) {
          state = state.toggle(columnIndex);
        }

        expect(state, initial,
            reason: 'an even number of toggles on the active column is '
                'the identity');
      }
    });

    test('toggling the active column an odd number of times flips direction',
        () {
      for (var i = 0; i < iterations; i++) {
        final columnIndex = random.nextInt(10);
        final ascending = random.nextBool();
        final initial =
            WTableSortState(columnIndex: columnIndex, ascending: ascending);

        final odd = random.nextInt(5) * 2 + 1; // 1,3,5,7,9
        var state = initial;
        for (var t = 0; t < odd; t++) {
          state = state.toggle(columnIndex);
        }

        expect(state.columnIndex, columnIndex);
        expect(state.ascending, !ascending,
            reason: 'an odd number of toggles on the active column flips '
                'direction');
      }
    });

    test('boundary: starting from an unsorted (null column) state', () {
      const unsorted = WTableSortState();
      // First tap on column 2 activates it ascending.
      final activated = unsorted.toggle(2);
      expect(activated.columnIndex, 2);
      expect(activated.ascending, isTrue);

      // Two further toggles on column 2 return to the activated state.
      final twice = activated.toggle(2).toggle(2);
      expect(twice, activated);
    });
  });

  group('Property 5: Pagination navigation button state correctness', () {
    // Validates: Requirements 3.9
    //
    // For any combination of currentPage (>= 1) and totalPages (>= 1), the
    // previous button SHALL be disabled if and only if currentPage == 1, and
    // the next button SHALL be disabled if and only if currentPage ==
    // totalPages.
    //
    // We generate random (totalItems, pageSize) and a valid currentPage, then
    // check the disabled invariants against an independent oracle computed from
    // the derived totalPages.

    test(
        'prev disabled iff currentPage == 1 and next disabled iff '
        'currentPage == totalPages (random valid states)', () {
      for (var i = 0; i < iterations; i++) {
        final totalItems = random.nextInt(1000); // 0..999
        final pageSize = random.nextInt(50) + 1; // 1..50 (positive)

        // Compute totalPages exactly as the implementation does, via an
        // independent oracle expression.
        final oracleTotalPages = totalItems <= 0
            ? 1
            : ((totalItems + pageSize - 1) ~/ pageSize);

        // Pick a valid current page in 1..oracleTotalPages.
        final currentPage = random.nextInt(oracleTotalPages) + 1;

        final state = WTablePagination(
          currentPage: currentPage,
          totalItems: totalItems,
          pageSize: pageSize,
        );

        // The derived totalPages must agree with the oracle and be >= 1.
        expect(state.totalPages, oracleTotalPages,
            reason: 'totalPages oracle mismatch for items=$totalItems '
                'pageSize=$pageSize');
        expect(state.totalPages, greaterThanOrEqualTo(1));

        // Previous disabled iff on the first page.
        expect(state.isPreviousDisabled, currentPage == 1,
            reason: 'prev disabled must hold iff currentPage==1 '
                '(page=$currentPage of ${state.totalPages})');

        // Next disabled iff on the last page.
        expect(state.isNextDisabled, currentPage == state.totalPages,
            reason: 'next disabled must hold iff currentPage==totalPages '
                '(page=$currentPage of ${state.totalPages})');
      }
    });

    test('on the first page prev is disabled and (if more pages) next enabled',
        () {
      for (var i = 0; i < iterations; i++) {
        final totalItems = random.nextInt(1000) + 1; // 1..1000
        final pageSize = random.nextInt(50) + 1;
        final state = WTablePagination(
          currentPage: 1,
          totalItems: totalItems,
          pageSize: pageSize,
        );

        expect(state.isPreviousDisabled, isTrue,
            reason: 'first page must always disable previous');
        // Next is disabled only when there is a single page.
        expect(state.isNextDisabled, state.totalPages == 1,
            reason: 'on page 1, next disabled iff there is only one page');
      }
    });

    test('on the last page next is disabled and (if more pages) prev enabled',
        () {
      for (var i = 0; i < iterations; i++) {
        final totalItems = random.nextInt(1000) + 1; // 1..1000
        final pageSize = random.nextInt(50) + 1;
        final totalPages = ((totalItems + pageSize - 1) ~/ pageSize);
        final state = WTablePagination(
          currentPage: totalPages,
          totalItems: totalItems,
          pageSize: pageSize,
        );

        expect(state.isNextDisabled, isTrue,
            reason: 'last page must always disable next');
        // Previous is disabled only when the last page is also the first.
        expect(state.isPreviousDisabled, totalPages == 1,
            reason: 'on the last page, prev disabled iff there is only one '
                'page');
      }
    });

    test('middle pages enable both navigation buttons', () {
      for (var i = 0; i < iterations; i++) {
        // Force at least 3 pages so a strict middle page exists.
        final pageSize = random.nextInt(50) + 1;
        final totalPages = random.nextInt(8) + 3; // 3..10
        // Choose item count that yields exactly `totalPages` pages: place items
        // in the last page's range so ceil(totalItems/pageSize) == totalPages.
        final totalItems = (totalPages - 1) * pageSize + (random.nextInt(pageSize) + 1);
        final currentPage = random.nextInt(totalPages - 2) + 2; // 2..totalPages-1

        final state = WTablePagination(
          currentPage: currentPage,
          totalItems: totalItems,
          pageSize: pageSize,
        );

        expect(state.totalPages, totalPages,
            reason: 'constructed totalItems must yield $totalPages pages');
        expect(state.isPreviousDisabled, isFalse,
            reason: 'a middle page must enable previous');
        expect(state.isNextDisabled, isFalse,
            reason: 'a middle page must enable next');
      }
    });

    test('empty data set reports a single page with both buttons disabled', () {
      for (var i = 0; i < iterations; i++) {
        final pageSize = random.nextInt(50) + 1;
        final state = WTablePagination(
          currentPage: 1,
          totalItems: 0,
          pageSize: pageSize,
        );

        expect(state.totalPages, 1,
            reason: 'an empty data set must still report a single page');
        expect(state.isPreviousDisabled, isTrue);
        expect(state.isNextDisabled, isTrue,
            reason: 'with one page, both navigation buttons are disabled');
      }
    });

    test('boundary: single full page disables both buttons', () {
      // totalItems == pageSize -> exactly one page.
      const state = WTablePagination(
        currentPage: 1,
        totalItems: 10,
        pageSize: 10,
      );
      expect(state.totalPages, 1);
      expect(state.isPreviousDisabled, isTrue);
      expect(state.isNextDisabled, isTrue);
    });

    test('boundary: exactly two pages toggles each button at its extreme', () {
      // 11 items at page size 10 -> 2 pages.
      const page1 = WTablePagination(
        currentPage: 1,
        totalItems: 11,
        pageSize: 10,
      );
      const page2 = WTablePagination(
        currentPage: 2,
        totalItems: 11,
        pageSize: 10,
      );

      expect(page1.totalPages, 2);
      expect(page1.isPreviousDisabled, isTrue);
      expect(page1.isNextDisabled, isFalse);

      expect(page2.totalPages, 2);
      expect(page2.isPreviousDisabled, isFalse);
      expect(page2.isNextDisabled, isTrue);
    });
  });
}
