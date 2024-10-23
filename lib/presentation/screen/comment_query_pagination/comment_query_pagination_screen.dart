import 'dart:async';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_sample_app/core/widget/add_comment_widget.dart';
import 'package:flutter_social_sample_app/core/widget/comment_widget.dart';
import 'package:flutter_social_sample_app/core/widget/common_snackbar.dart';
import 'package:flutter_social_sample_app/core/widget/dialog/error_dialog.dart';
import 'package:flutter_social_sample_app/core/widget/dialog/progress_dialog_widget.dart';

class CommentQueryPaginationScreen extends StatefulWidget {
  final String? communityId;
  final bool isPublic;
  final String referenceType;
  final String referenceId;
  const CommentQueryPaginationScreen(
      {super.key,
      this.communityId,
      required this.isPublic,
      required this.referenceType,
      required this.referenceId});

  @override
  State<CommentQueryPaginationScreen> createState() =>
      _CommentQueryPaginationScreenState();
}

class _CommentQueryPaginationScreenState
    extends State<CommentQueryPaginationScreen> {
  List<AmityComment> amityComments = <AmityComment>[];
  late PagingController<AmityComment> _controller;

  final scrollcontroller = ScrollController();
  bool loading = false;

  AmityComment? _replyToComment;

  AmityCommentSortOption _sortOption = AmityCommentSortOption.LAST_CREATED;

  final mentionUsers = <AmityUser>[];

  AmityCommentDataTypeFilter? dataTypes;

  bool _includeDeleted = false;

  @override
  void initState() {

    if (widget.referenceType == 'post') {
      _controller = PagingController(
        pageFuture: (token) => AmitySocialClient.newCommentRepository()
            .getComments()
            .post(widget.referenceId)
            .sortBy(_sortOption)
            .parentId(null)
            .includeDeleted(true)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(
          () async {
            if (_controller.error == null) {
            setState(() {
              amityComments.clear();
              amityComments.addAll(_controller.loadedItems);
            });
          } else {
            //Error on pagination controller
            setState(() {});
            print(_controller.stacktrace);
            ErrorDialog.show(context,
                title: 'Error',
                message: '${_controller.error}\n${_controller.stacktrace}');
          }
          },
        );
    }
    if (widget.referenceType == 'story') {
      _controller = PagingController(
        pageFuture: (token) => AmitySocialClient.newCommentRepository()
            .getComments()
            .story(widget.referenceId)
            .sortBy(_sortOption)
            .parentId(null)
            .includeDeleted(true)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(
          () async {
            if (_controller.error == null) {
              // Instead of clearing and re-adding all items, directly append new items
              // This assumes `amityComments` is a List that can be compared with _controller.loadedItems for duplicates
              var newComments = _controller.loadedItems;
              // Append only new comments
              var currentIds = amityComments.map((e) => e.commentId).toSet();
              var newItems = newComments
                  .where((item) => !currentIds.contains(item.commentId))
                  .toList();
              if (newItems.isNotEmpty) {
                amityComments.addAll(newItems);
              }
            } else {}
          },
        );
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.fetchNextPage();
    });

    scrollcontroller.addListener(loadnextpage);
  }

  void loadnextpage() {
    if ((scrollcontroller.position.pixels ==
            scrollcontroller.position.maxScrollExtent) &&
        _controller.hasMoreItems) {
      setState(() {
        _controller.fetchNextPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment Feed'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 1,
                  child: Text(AmityCommentSortOption.LAST_CREATED.apiKey),
                ),
                PopupMenuItem(
                  value: 8,
                  child: Text(AmityCommentSortOption.LAST_UPDATED.apiKey),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Text(AmityCommentSortOption.FIRST_CREATED.apiKey),
                ),
                PopupMenuItem(
                  value: 9,
                  child: Text(AmityCommentSortOption.FIRST_UPDATED.apiKey),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Text('Excat TEXT'),
                ),
                const PopupMenuItem(
                  value: 4,
                  child: Text('Excat IMAGE'),
                ),
                const PopupMenuItem(
                  value: 11,
                  child: Text('Excat IMAGE & TEXT'),
                ),
                const PopupMenuItem(
                  value: 5,
                  child: Text('Any TEXT'),
                ),
                const PopupMenuItem(
                  value: 6,
                  child: Text('Any IMAGE'),
                ),
                const PopupMenuItem(
                  value: 12,
                  child: Text('Any IMAGE & TEXT'),
                ),
                const PopupMenuItem(
                  value: 7,
                  child: Text('Clear'),
                ),
                const PopupMenuItem(
                  value: 10,
                  child: Text('Include Deleted'),
                ),
                const PopupMenuItem(
                  value: 13,
                  child: Text('Exclude Deleted'),
                ),
              ];
            },
            child: const Icon(
              Icons.sort_rounded,
              size: 24,
            ),
            onSelected: (index1) {
              if (index1 == 1) {
                _sortOption = AmityCommentSortOption.LAST_CREATED;
              }
              if (index1 == 2) {
                _sortOption = AmityCommentSortOption.FIRST_CREATED;
              }
              if (index1 == 8) {
                _sortOption = AmityCommentSortOption.LAST_UPDATED;
              }
              if (index1 == 9) {
                _sortOption = AmityCommentSortOption.FIRST_UPDATED;
              }

              if (index1 == 3) {
                dataTypes = AmityCommentDataTypeFilter.exact(
                    dataTypes: [AmityDataType.TEXT]);
              }

              if (index1 == 4) {
                dataTypes = AmityCommentDataTypeFilter.exact(
                    dataTypes: [AmityDataType.IMAGE]);
              }
              if (index1 == 11) {
                dataTypes = AmityCommentDataTypeFilter.exact(
                    dataTypes: [AmityDataType.TEXT, AmityDataType.IMAGE]);
              }

              if (index1 == 5) {
                dataTypes = AmityCommentDataTypeFilter.any(
                    dataTypes: [AmityDataType.TEXT]);
              }

              if (index1 == 6) {
                dataTypes = AmityCommentDataTypeFilter.any(
                    dataTypes: [AmityDataType.IMAGE]);
              }

              if (index1 == 12) {
                dataTypes = AmityCommentDataTypeFilter.any(
                    dataTypes: [AmityDataType.IMAGE, AmityDataType.TEXT]);
              }

              if (index1 == 7) {
                dataTypes = null;
              }

              if (index1 == 10) {
                _includeDeleted = true;
              }

              if (index1 == 13) {
                _includeDeleted = false;
              }

              setState(() {});
              _controller.reset();
              _controller.fetchNextPage();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: amityComments.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: () async {
                      _controller.reset();
                      _controller.fetchNextPage();
                    },
                    child: ListView.builder(
                      controller: scrollcontroller,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: amityComments.length,
                      itemBuilder: (context, index) {
                        final amityComment = amityComments[index];
                        return CommentWidget(
                          widget.referenceType,
                          widget.referenceId,
                          amityComment,
                          (value) {
                            setState(() {
                              _replyToComment = value;
                            });
                          },
                          key: UniqueKey(),
                          communityId: widget.communityId,
                          isPublic: widget.isPublic,
                        );
                      },
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    child: _controller.isFetching
                        ? const CircularProgressIndicator()
                        : const Text('No Comment'),
                  ),
          ),
          if (_controller.isFetching && amityComments.isNotEmpty)
            Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          if (_replyToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey.shade200),
              child: Row(
                children: [
                  const Text('Reply to '),
                  Text('@${_replyToComment!.user!.userId}'),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _replyToComment = null;
                      });
                    },
                    icon: const Icon(
                      Icons.clear_rounded,
                    ),
                  )
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.all(12),
            child: AddCommentWidget(
              AmityCoreClient.getCurrentUser(),
              showMediaButton: true,
              (text, user, attachments) async {
                final completer = Completer();
                try {
                  ProgressDialog.showCompleter(context, completer);

                  mentionUsers.clear();
                  mentionUsers.addAll(user);

                  //Clean up mention user list, as user might have removed some tagged user
                  mentionUsers.removeWhere(
                      (element) => !text.contains(element.displayName!));

                  final amityMentioneesMetadata = mentionUsers
                      .map<AmityUserMentionMetadata>((e) =>
                          AmityUserMentionMetadata(
                              userId: e.userId!,
                              index: text.indexOf('@${e.displayName!}'),
                              length: e.displayName!.length))
                      .toList();

                  Map<String, dynamic> metadata =
                      AmityMentionMetadataCreator(amityMentioneesMetadata)
                          .create();

                  List<CommentImageAttachment> amityImages = [];
                  if (attachments.isNotEmpty) {
                    for (var element in attachments) {
                      final image = await waitForUploadComplete(
                          AmityCoreClient.newFileRepository()
                              .uploadImage(element)
                              .stream);
                      amityImages
                          .add(CommentImageAttachment(fileId: image.fileId!));
                    }
                  }

                  if (_replyToComment != null) {
                    ///Add comment to [_replyToComment] comment
                    final _comment = await _replyToComment!
                        .comment()
                        .create()
                        .attachments(amityImages)
                        .text(text)
                        .mentionUsers(
                            mentionUsers.map<String>((e) => e.userId!).toList())
                        .metadata(metadata)
                        .send();

                    setState(() {
                      _replyToComment = null;
                    });

                    return;
                  }

                  if (widget.referenceType == "post") {
                    final _comment =
                        await AmitySocialClient.newCommentRepository()
                            .createComment()
                            .post(widget.referenceId)
                            .create()
                            .attachments(amityImages)
                            .text(text)
                            .mentionUsers(mentionUsers
                                .map<String>((e) => e.userId!)
                                .toList())
                            .metadata(metadata)
                            .send();
                  } else if (widget.referenceType == "story") {
                    final _comment =
                        await AmitySocialClient.newCommentRepository()
                            .createComment()
                            .story(widget.referenceId)
                            .create()
                            .attachments(amityImages)
                            .text(text)
                            .mentionUsers(mentionUsers
                                .map<String>((e) => e.userId!)
                                .toList())
                            .metadata(metadata)
                            .send();
                  }

                  return;
                } catch (error, stackTrace) {
                  if (error is AmityException) {
                    CommonSnackbar.showNagativeSnackbar(
                        context, 'Error', '$error\n${error.data}');
                  } else {
                    CommonSnackbar.showNagativeSnackbar(
                        context, 'Error', error.toString());
                  }
                } finally {
                  completer.complete();
                }
              },
              communityId: widget.communityId,
              isPublic: widget.isPublic,
            ),
          ),
        ],
      ),
    );
  }

  Future<AmityImage> waitForUploadComplete(Stream<AmityUploadResult> source) {
    final completer = Completer<AmityImage>();
    source.listen((event) {
      event.when(
        progress: (uploadInfo, cancelToken) {},
        complete: (file) => completer.complete(file),
        error: (error) => completer.completeError(error),
        cancel: () {},
      );
    });
    return completer.future;
  }
}