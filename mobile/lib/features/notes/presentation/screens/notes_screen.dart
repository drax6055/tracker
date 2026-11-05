
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/notes_controller.dart';
import 'note_editor_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _selectedColorFilter = 'ALL';
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  bool _isGridView = false;

  static const Map<String, Color> stickyColors = {
    'yellow': Color(0xFFFFF9A6),
    'lime': Color(0xFFD4F8D3),
    'cyan': Color(0xFFD0F4F7),
    'pink': Color(0xFFFFD4E5),
    'orange': Color(0xFFFFE0C8),
    'purple': Color(0xFFE8DBF8),
  };

  static const Map<String, Color> stickyHeaderColors = {
    'yellow': Color(0xFFF9E870),
    'lime': Color(0xFFB5EDB4),
    'cyan': Color(0xFFB1E7EB),
    'pink': Color(0xFFF7B9D2),
    'orange': Color(0xFFFACBB1),
    'purple': Color(0xFFD7C2F0),
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    }
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed != null) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    }
    return rawDate.toString();
  }

  void _confirmDelete(String id, String title) {
    BrutalDialog.show(
      context: context,
      title: 'DISCARD STICKY NOTE?',
      content: Text(
        'Delete "$title"? This action cannot be undone.',
        style: const TextStyle(color: BrutalColors.textSecondary, height: 1.4),
      ),
      confirmText: 'DELETE NOTE',
      confirmColor: BrutalColors.red,
      cancelText: 'CANCEL',
      onConfirm: () async {
        await ref.read(notesProvider.notifier).deleteNote(id);
        if (mounted) {
          BrutalToast.showSuccess(context, 'STICKY NOTE REMOVED');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);

    final filtered = allNotes.where((n) {
      final color = (n['color'] ?? 'yellow').toString().toLowerCase();
      if (_selectedColorFilter != 'ALL' && color != _selectedColorFilter.toLowerCase()) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        final title = (n['title'] ?? '').toString().toLowerCase();
        final content = (n['content'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !content.contains(q)) return false;
      }
      return true;
    }).toList();

    final pinnedNotes = filtered.where((n) => n['isPinned'] == true).toList();
    final otherNotes = filtered.where((n) => n['isPinned'] != true).toList();
    final swipeOrderedNotes = [...pinnedNotes, ...otherNotes];

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'STICKY NOTES // PINBOARD',
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_carousel : Icons.grid_view,
              color: BrutalColors.textPrimary,
              size: 24,
            ),
            tooltip: _isGridView ? 'Switch to Swipe View' : 'Switch to Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            tooltip: 'Add Sticky Note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrutalColors.primaryYellow,
        foregroundColor: BrutalColors.textDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white, width: 2.5),
          borderRadius: BorderRadius.zero,
        ),
        icon: const Icon(Icons.note_add, size: 20),
        label: Text(
          '+ NEW STICKY',
          style: BrutalTypography.sticker.copyWith(
            color: BrutalColors.textDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Strip (Matching Ledger Log Screen)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BrutalColors.border, width: 2.5)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                    cursorColor: BrutalColors.primaryYellow,
                    decoration: InputDecoration(
                      hintText: 'SEARCH NOTES BY TITLE OR CONTENT...',
                      hintStyle: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: BrutalColors.textPrimary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: BrutalColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', BrutalColors.primaryYellow),
                        const SizedBox(width: 8),
                        _buildFilterChip('YELLOW', stickyColors['yellow']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('LIME', stickyColors['lime']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('CYAN', stickyColors['cyan']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('PINK', stickyColors['pink']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('ORANGE', stickyColors['orange']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('PURPLE', stickyColors['purple']!),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Notes Display (Swipe Deck by default, Grid View optional)
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context)
                  : _isGridView
                      ? RefreshIndicator(
                          color: BrutalColors.primaryYellow,
                          backgroundColor: BrutalColors.surface,
                          onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            children: [
                              if (pinnedNotes.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.push_pin, size: 16, color: BrutalColors.primaryYellow),
                                    const SizedBox(width: 6),
                                    Text(
                                      'PINNED NOTES (${pinnedNotes.length})',
                                      style: BrutalTypography.sticker.copyWith(
                                        color: BrutalColors.primaryYellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildNotesGrid(pinnedNotes),
                                const SizedBox(height: 20),
                              ],
                              if (otherNotes.isNotEmpty) ...[
                                if (pinnedNotes.isNotEmpty)
                                  Row(
                                    children: [
                                      Text(
                                        'OTHER NOTES (${otherNotes.length})',
                                        style: BrutalTypography.sticker.copyWith(
                                          color: BrutalColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (pinnedNotes.isNotEmpty) const SizedBox(height: 10),
                                _buildNotesGrid(otherNotes),
                              ],
                            ],
                          ),
                        )
                      : _buildSwipeDeckView(swipeOrderedNotes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color accent) {
    final isSelected = _selectedColorFilter.toUpperCase() == label.toUpperCase();
    return BrutalChip(
      label: label,
      backgroundColor: isSelected ? accent : BrutalColors.surfaceElevated,
      textColor: isSelected ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSelected ? 3.0 : 0.0,
      onTap: () => setState(() => _selectedColorFilter = label),
    );
  }

  Widget _buildSwipeDeckView(List<Map<String, dynamic>> notes) {
    if (_currentPage >= notes.length) {
      _currentPage = (notes.length - 1).clamp(0, notes.length);
    }

    return Column(
      children: [
        // Navigation bar & swipe indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrutalColors.surfaceElevated,
                  border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swipe, size: 14, color: BrutalColors.primaryYellow),
                    const SizedBox(width: 6),
                    Text(
                      'SWIPE // NOTE ${_currentPage + 1} OF ${notes.length}',
                      style: BrutalTypography.sticker.copyWith(
                        color: BrutalColors.primaryYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: BrutalColors.textPrimary, size: 24),
                    tooltip: 'Previous Note',
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: BrutalColors.textPrimary, size: 24),
                    tooltip: 'Next Note',
                    onPressed: _currentPage < notes.length - 1
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontally swipeable PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: _buildSwipeStickyNote(context, notes[index]),
              );
            },
          ),
        ),

        // Indicator dots strip
        if (notes.length > 1) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 84),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                notes.length > 12 ? 12 : notes.length,
                (idx) {
                  final isCurrent = idx == _currentPage;
                  final noteColor = (notes[idx]['color'] ?? 'yellow').toString().toLowerCase();
                  final dotColor = stickyColors[noteColor] ?? BrutalColors.primaryYellow;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrent ? dotColor : BrutalColors.surfaceElevated,
                      border: Border.all(
                        color: isCurrent ? Colors.white : BrutalColors.borderDim,
                        width: 1.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 84),
        ],
      ],
    );
  }

  Widget _buildSwipeStickyNote(BuildContext context, Map<String, dynamic> note) {
    final id = (note['id'] ?? note['_id'] ?? '').toString();
    final title = (note['title'] ?? 'Untitled Sticky').toString();
    final content = (note['content'] ?? '').toString();
    final colorKey = (note['color'] ?? 'yellow').toString().toLowerCase();
    final isPinned = note['isPinned'] == true;
    final dateDisplay = _formatDate(note['createdAtClient'] ?? note['createdAt']);
    final headerBg = stickyHeaderColors[colorKey] ?? stickyHeaderColors['yellow']!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: BrutalColors.surfaceCard,
          border: Border.all(color: headerBg, width: 2.5),
          boxShadow: [
            BoxShadow(color: headerBg, offset: const Offset(5.0, 5.0)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Windows Handle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: headerBg,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 2.0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: headerBg,
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'STICKY // ${colorKey.toUpperCase()}',
                    style: BrutalTypography.sticker.copyWith(
                      color: const Color(0xFF1E1E1E),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (isPinned) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                      ),
                      child: const Text(
                        'PINNED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Pin toggle icon
                  GestureDetector(
                    onTap: () => ref.read(notesProvider.notifier).togglePin(id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 20,
                        color: isPinned ? const Color(0xFF8B6B00) : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete quick action
                  GestureDetector(
                    onTap: () => _confirmDelete(id, title),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BrutalTypography.headingMedium.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: BrutalColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const Divider(color: BrutalColors.borderFaint, thickness: 1.5, height: 12),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Text(
                  content.isEmpty ? '(Empty Note - Tap to write)' : content,
                  style: BrutalTypography.bodyLarge.copyWith(
                    fontSize: 14.5,
                    height: 1.5,
                    color: content.isEmpty ? BrutalColors.textMuted : BrutalColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Date / Time Stamp Sticker Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                color: BrutalColors.surfaceElevated,
                border: Border(
                  top: BorderSide(color: BrutalColors.borderFaint, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: headerBg),
                      const SizedBox(width: 6),
                      Text(
                        dateDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BrutalColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 16, color: BrutalColors.primaryYellow),
                      const SizedBox(width: 4),
                      Text(
                        'TAP TO EDIT',
                        style: BrutalTypography.sticker.copyWith(
                          color: BrutalColors.primaryYellow,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid(List<Map<String, dynamic>> notes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 650 ? 3 : (constraints.maxWidth > 400 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            return _buildStickyNoteCard(context, notes[index]);
          },
        );
      },
    );
  }

  Widget _buildStickyNoteCard(BuildContext context, Map<String, dynamic> note) {
    final id = (note['id'] ?? note['_id'] ?? '').toString();
    final title = (note['title'] ?? 'Untitled Sticky').toString();
    final content = (note['content'] ?? '').toString();
    final colorKey = (note['color'] ?? 'yellow').toString().toLowerCase();
    final isPinned = note['isPinned'] == true;
    final dateDisplay = _formatDate(note['createdAtClient'] ?? note['createdAt']);

    final headerBg = stickyHeaderColors[colorKey] ?? stickyHeaderColors['yellow']!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: BrutalColors.surfaceCard,
          border: Border.all(color: headerBg, width: 2.0),
          boxShadow: [
            BoxShadow(color: headerBg, offset: const Offset(3.5, 3.5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sticky Windows Handle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: headerBg,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: headerBg,
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1.0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    colorKey.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  // Pin toggle icon
                  GestureDetector(
                    onTap: () => ref.read(notesProvider.notifier).togglePin(id),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: isPinned ? const Color(0xFF8B6B00) : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete quick action
                  GestureDetector(
                    onTap: () => _confirmDelete(id, title),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // Note Title (White and crisp, 100% visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BrutalTypography.headingSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: BrutalColors.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
            ),

            // Content Preview (High contrast textSecondary)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Text(
                  content.isEmpty ? '(Empty Note)' : content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: content.isEmpty ? BrutalColors.textMuted : BrutalColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Date / Time Stamp Sticker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: BrutalColors.surfaceElevated,
                border: Border(
                  top: BorderSide(color: BrutalColors.borderFaint, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: headerBg),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: stickyColors['yellow'],
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.white, offset: Offset(4, 4)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.sticky_note_2_outlined, size: 40, color: Color(0xFF1E1E1E)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'WINDOWS PINBOARD EMPTY',
              style: BrutalTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture quick financial thoughts, reminders, memo checklists, or transaction tags on colorful sticky notes.',
              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BrutalColors.primaryYellow,
                foregroundColor: BrutalColors.textDark,
                elevation: 0,
                side: const BorderSide(color: Colors.white, width: 2.5),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: const Icon(Icons.add, color: BrutalColors.textDark),
              label: Text(
                '+ CREATE YOUR FIRST STICKY NOTE',
                style: BrutalTypography.sticker.copyWith(
                  color: BrutalColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
