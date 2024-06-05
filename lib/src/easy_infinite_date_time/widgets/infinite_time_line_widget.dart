import 'package:flutter/material.dart';
import '../../properties/properties.dart';
import '../../utils/utils.dart';
import '../../widgets/easy_day_widget/easy_day_widget.dart';
import 'web_scroll_behavior.dart';

part 'easy_infinite_date_timeline_controller.dart';

class InfiniteTimeLineWidget extends StatefulWidget {
  InfiniteTimeLineWidget({
    super.key,
    this.inactiveDates,
    this.dayProps = const EasyDayProps(),
    this.locale = "en_US",
    this.timeLineProps = const EasyTimeLineProps(),
    this.onDateChange,
    this.itemBuilder,
    this.physics,
    this.controller,
    required this.firstDate,
    required this.focusedDate,
    required this.activeDayTextColor,
    required this.activeDayColor,
    required this.lastDate,
    required this.selectionMode,
    this.scrollDirection = Axis.horizontal,
  })  : assert(timeLineProps.hPadding > -1,
  "Can't set timeline hPadding less than zero."),
        assert(timeLineProps.separatorPadding > -1,
        "Can't set timeline separatorPadding less than zero."),
        assert(timeLineProps.vPadding > -1,
        "Can't set timeline vPadding less than zero."),
        assert(
        !lastDate.isBefore(firstDate),
        'lastDate $lastDate must be on or after firstDate $firstDate.',
        );

  final Axis scrollDirection;

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? focusedDate;
  final Color activeDayTextColor;
  final Color activeDayColor;
  final List<DateTime>? inactiveDates;
  final EasyTimeLineProps timeLineProps;
  final EasyDayProps dayProps;
  final OnDateChangeCallBack? onDateChange;
  final ItemBuilderCallBack? itemBuilder;
  final String locale;
  final SelectionMode selectionMode;
  final EasyInfiniteDateTimelineController? controller;
  final ScrollPhysics? physics;

  @override
  State<InfiniteTimeLineWidget> createState() => _InfiniteTimeLineWidgetState();
}

class _InfiniteTimeLineWidgetState extends State<InfiniteTimeLineWidget> {
  EasyDayProps get _dayProps => widget.dayProps;
  EasyTimeLineProps get _timeLineProps => widget.timeLineProps;

  bool get _isLandscapeMode => _dayProps.landScapeMode;
  double get _dayWidth => _dayProps.width;
  double get _dayHeight => _dayProps.height;

  late int _daysCount;
  late ScrollController _controller;

  DateTime get _focusDate => widget.focusedDate ?? widget.firstDate;
  double _itemExtend = 0.0;

  @override
  void initState() {
    super.initState();
    _initItemExtend();
    _attachEasyController();
    _daysCount =
        EasyDateUtils.calculateDaysCount(widget.firstDate, widget.lastDate);
    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialOffset());
  }

  void _jumpToInitialOffset() {
    final initialScrollOffset = _getScrollOffset();
    if (_controller.hasClients) {
      _controller.jumpTo(initialScrollOffset);
    }
  }

  @override
  void didUpdateWidget(covariant InfiniteTimeLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachEasyController();
    } else if (widget.timeLineProps != oldWidget.timeLineProps ||
        widget.dayProps != oldWidget.dayProps) {
      _initItemExtend();
    } else if (widget.selectionMode != oldWidget.selectionMode) {
      _jumpToInitialOffset();
    }
  }

  void _attachEasyController() => widget.controller?._attachEasyDateState(this);

  void _detachEasyController() => widget.controller?._detachEasyDateState();

  @override
  void dispose() {
    _controller.dispose();
    _detachEasyController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTimeLineBackgroundColor = _timeLineProps.decoration == null
        ? _timeLineProps.backgroundColor
        : null;
    final effectiveTimeLineBorderRadius =
        _timeLineProps.decoration?.borderRadius ?? BorderRadius.zero;

    return Container(
      height: widget.scrollDirection == Axis.horizontal
          ? (_isLandscapeMode ? _dayWidth : _dayHeight)
          : null,
      width: widget.scrollDirection == Axis.vertical
          ? (_isLandscapeMode ? _dayHeight : _dayWidth)
          : null,
      margin: _timeLineProps.margin,
      color: effectiveTimeLineBackgroundColor,
      decoration: _timeLineProps.decoration,
      child: ClipRRect(
        borderRadius: effectiveTimeLineBorderRadius,
        child: CustomScrollView(
          scrollDirection: widget.scrollDirection,
          scrollBehavior: EasyCustomScrollBehavior(),
          controller: _controller,
          physics: widget.physics,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.scrollDirection == Axis.horizontal
                    ? _timeLineProps.hPadding
                    : _timeLineProps.vPadding,
                vertical: widget.scrollDirection == Axis.vertical
                    ? _timeLineProps.vPadding
                    : _timeLineProps.hPadding,
              ),
              sliver: SliverFixedExtentList.builder(
                itemExtent: _itemExtend,
                itemBuilder: (context, index) {
                  final currentDate =
                  widget.firstDate.add(Duration(days: index));
                  final isSelected =
                  EasyDateUtils.isSameDay(_focusDate, currentDate);

                  bool isDisabledDay = false;

                  if (widget.inactiveDates != null) {
                    for (DateTime inactiveDate in widget.inactiveDates!) {
                      if (EasyDateUtils.isSameDay(currentDate, inactiveDate)) {
                        isDisabledDay = true;
                        break;
                      }
                    }
                  }
                  return Padding(
                    key: ValueKey<DateTime>(currentDate),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.scrollDirection == Axis.horizontal
                          ? _timeLineProps.separatorPadding / 2
                          : 0.0,
                      vertical: widget.scrollDirection == Axis.vertical
                          ? _timeLineProps.separatorPadding / 2
                          : 0.0,
                    ),
                    child: widget.itemBuilder != null
                        ? _dayItemBuilder(
                      context,
                      isSelected,
                      currentDate,
                    )
                        : EasyDayWidget(
                      easyDayProps: _dayProps,
                      date: currentDate,
                      locale: widget.locale,
                      isSelected: isSelected,
                      isDisabled: isDisabledDay,
                      onDayPressed: () => _onDayTapped(currentDate),
                      activeTextColor: widget.activeDayTextColor,
                      activeDayColor: widget.activeDayColor,
                    ),
                  );
                },
                itemCount: _daysCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayItemBuilder(
      BuildContext context,
      bool isSelected,
      DateTime date,
      ) {
    return widget.itemBuilder!(
      context,
      date,
      isSelected,
          () => _onDayTapped(date),
    );
  }

  void _onDayTapped(DateTime currentDate) {
    widget.onDateChange?.call(currentDate);
    final selectionMode = widget.selectionMode;
    if (selectionMode.isAutoCenter || selectionMode.isAlwaysFirst) {
      final offset = _getScrollOffset(currentDate);
      _controller.animateTo(
        offset,
        duration: selectionMode.duration ??
            EasyConstants.selectionModeAnimationDuration,
        curve: selectionMode.curve ?? Curves.linear,
      );
    }
  }

  double _getScrollOffset([DateTime? lastDate]) {
    final effectiveLastDate = lastDate ?? widget.focusedDate;

    if (effectiveLastDate != null) {
      final scrollHelper = InfiniteTimelineScrollHelper(
        firstDate: widget.firstDate,
        lastDate: effectiveLastDate,
        dayWidth: _itemExtend,
        maxScrollExtent: _controller.position.maxScrollExtent,
        screenWidth: _controller.position.viewportDimension,
      );
      return switch (widget.selectionMode) {
        SelectionModeNone() ||
        SelectionModeAlwaysFirst() =>
            scrollHelper.getScrollPositionForFirstDate(),
        SelectionModeAutoCenter() =>
            scrollHelper.getScrollPositionForCenterDate(),
      };
    } else {
      return 0.0;
    }
  }

  void _initItemExtend() {
    _itemExtend = (_isLandscapeMode ? _dayHeight : _dayWidth) +
        _timeLineProps.separatorPadding;
  }
}
