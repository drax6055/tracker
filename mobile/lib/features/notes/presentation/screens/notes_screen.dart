import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
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

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'STICKY NOTES // PINBOARD',
        actions: [
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
            // Search Bar & Filter Strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: BrutalColors.surface,
                border: Border(
                  bottom: BorderSide(color: BrutalColors.border, width: 2.0),
                ),
              ),
              child: Column(
                children: [
                  // Search Box
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: BrutalColors.surfaceElevated,
                      border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: BrutalColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'SEARCH NOTES BY TITLE OR CONTENT...',
                              hintStyle: TextStyle(color: BrutalColors.textMuted, fontSize: 11),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.close, color: BrutalColors.textMuted, size: 18),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Color Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('ALL', Colors.white, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('YELLOW', stickyColors['yellow']!, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('LIME', stickyColors['lime']!, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('CYAN', stickyColors['cyan']!, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('PINK', stickyColors['pink']!, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('ORANGE', stickyColors['orange']!, Colors.black),
                        const SizedBox(width: 8),
                        _buildFilterPill('PURPLE', stickyColors['purple']!, Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Notes Grid or Empty State
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
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
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, Color bg, Color text) {
    final isSelected = _selectedColorFilter.toUpperCase() == label.toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _selectedColorFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? bg : BrutalColors.surfaceElevated,
          border: Border.all(
            color: isSelected ? Colors.white : BrutalColors.borderDim,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.white, offset: Offset(2, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSelected ? text : BrutalColors.textSecondary,
            letterSpacing: 0.8,
          ),
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

    final noteBg = stickyColors[colorKey] ?? stickyColors['yellow']!;
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
          color: noteBg,
          border: Border.all(color: const Color(0xFF1E1E1E), width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.white, offset: Offset(3, 3)),
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
                  const Spacer(),
                  // Pin toggle icon
                  GestureDetector(
                    onTap: () => ref.read(notesProvider.notifier).togglePin(id),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: isPinned ? const Color(0xFF8B6B00) : const Color(0xFF555555),
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
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),

            // Note Title
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
            ),

            // Content Preview
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
                    color: content.isEmpty ? const Color(0xFF888888) : const Color(0xFF222222),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Date / Time Stamp Sticker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0x181E1E1E),
                border: Border(
                  top: BorderSide(color: Color(0x221E1E1E), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 12, color: Color(0xFF555555)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
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
