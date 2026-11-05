import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/notes_controller.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;
  late bool _isPinned;
  late String _createdAtDisplay;
  bool _isSaving = false;

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
    final n = widget.note;
    _titleController = TextEditingController(text: n?['title'] ?? '');
    _contentController = TextEditingController(text: n?['content'] ?? '');
    _selectedColor = n?['color'] ?? 'yellow';
    if (!stickyColors.containsKey(_selectedColor)) _selectedColor = 'yellow';
    _isPinned = n?['isPinned'] == true;

    if (n != null) {
      final rawDate = n['createdAtClient'] ?? n['createdAt'] ?? '';
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) {
        _createdAtDisplay = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      } else if (rawDate.isNotEmpty) {
        _createdAtDisplay = rawDate.toString();
      } else {
        _createdAtDisplay = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      }
    } else {
      _createdAtDisplay = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      BrutalToast.showError(context, 'PLEASE ENTER A TITLE OR NOTE CONTENT');
      return;
    }

    setState(() => _isSaving = true);
    final isEditing = widget.note != null;
    final noteId = widget.note?['id'] ?? widget.note?['_id'] ?? 'note_${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();

    final noteData = {
      'id': noteId,
      'title': title.isEmpty ? 'Untitled Sticky' : title,
      'content': content,
      'color': _selectedColor,
      'isPinned': _isPinned,
      'createdAt': widget.note?['createdAt'] ?? nowIso,
      'createdAtClient': widget.note?['createdAtClient'] ?? _createdAtDisplay,
      'updatedAt': nowIso,
    };

    if (isEditing) {
      await ref.read(notesProvider.notifier).updateNote(noteData);
      if (mounted) {
        BrutalToast.showSuccess(context, 'STICKY NOTE UPDATED');
        context.pop();
      }
    } else {
      await ref.read(notesProvider.notifier).addNote(noteData);
      if (mounted) {
        BrutalToast.showSuccess(context, 'STICKY NOTE PINNED');
        context.pop();
      }
    }
  }

  void _confirmDelete() {
    BrutalDialog.show(
      context: context,
      title: 'DISCARD STICKY NOTE?',
      content: const Text(
        'Are you sure you want to delete this sticky note? This action cannot be reversed.',
        style: TextStyle(color: BrutalColors.textSecondary, height: 1.4),
      ),
      confirmText: 'DELETE NOTE',
      confirmColor: BrutalColors.red,
      cancelText: 'CANCEL',
      onConfirm: () async {
        final id = (widget.note?['id'] ?? widget.note?['_id'] ?? '').toString();
        if (id.isNotEmpty) {
          await ref.read(notesProvider.notifier).deleteNote(id);
          if (mounted) {
            BrutalToast.showSuccess(context, 'NOTE DELETED');
            context.pop();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final noteHeaderBg = stickyHeaderColors[_selectedColor] ?? stickyHeaderColors['yellow']!;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: isEditing ? 'EDIT STICKY NOTE' : 'NEW STICKY NOTE',
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: BrutalColors.red),
              tooltip: 'Delete Note',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sticky Note Canvas (Windows-style)
              Container(
                decoration: BoxDecoration(
                  color: BrutalColors.surfaceCard,
                  border: Border.all(color: noteHeaderBg, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: noteHeaderBg, offset: const Offset(5, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sticky Note Top Bar (Windows Handle)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: noteHeaderBg,
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 2.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: noteHeaderBg,
                              border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'WINDOWS STICKY // ${_selectedColor.toUpperCase()}',
                              style: BrutalTypography.sticker.copyWith(
                                color: const Color(0xFF1E1E1E),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isPinned = !_isPinned),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isPinned ? BrutalColors.primaryYellow : Colors.white,
                                border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                    size: 14,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isPinned ? 'PINNED' : 'PIN',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title Field (White font, completely visible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: TextField(
                        controller: _titleController,
                        style: BrutalTypography.headingMedium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: BrutalColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        cursorColor: BrutalColors.primaryYellow,
                        cursorWidth: 3.0,
                        decoration: InputDecoration(
                          hintText: 'NOTE TITLE...',
                          hintStyle: BrutalTypography.headingMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.textMuted,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Divider line inside note
                    const Divider(color: BrutalColors.borderFaint, thickness: 1.5, height: 16),

                    // Content Field (White font, completely visible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 8,
                        style: BrutalTypography.bodyLarge.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: BrutalColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: BrutalColors.primaryYellow,
                        cursorWidth: 3.0,
                        decoration: InputDecoration(
                          hintText: 'Type your notes, checklist, memos, financial reminders here...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: BrutalColors.textMuted,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Date & Time Stamp Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border(
                          top: BorderSide(color: BrutalColors.borderFaint, width: 1.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: noteHeaderBg),
                          const SizedBox(width: 6),
                          Text(
                            'CREATED: $_createdAtDisplay',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Color Palette Picker
              Text('STICKY COLOR PALETTE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrutalColors.surface,
                  border: Border.all(color: BrutalColors.border, width: 2.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stickyColors.entries.map((entry) {
                    final colorKey = entry.key;
                    final colorVal = entry.value;
                    final isSelected = _selectedColor == colorKey;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorKey),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 44 : 36,
                        height: isSelected ? 44 : 36,
                        decoration: BoxDecoration(
                          color: colorVal,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.black,
                            width: isSelected ? 3.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? BrutalColors.primaryYellow : Colors.black,
                              offset: Offset(isSelected ? 3 : 2, isSelected ? 3 : 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 20, color: Color(0xFF1E1E1E))
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // Save Action Button
              BrutalButton(
                text: isEditing ? 'SAVE STICKY NOTE' : '+ PIN STICKY NOTE',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveNote,
                backgroundColor: BrutalColors.primaryYellow,
                textColor: BrutalColors.textDark,
                height: 52,
              ),

              if (isEditing) ...[
                const SizedBox(height: 12),
                BrutalButton(
                  text: 'DISCARD NOTE',
                  onPressed: _confirmDelete,
                  backgroundColor: BrutalColors.surfaceElevated,
                  textColor: BrutalColors.red,
                  height: 48,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

