import 'package:flutter/material.dart';

class SelectWidget<T> extends StatefulWidget {
  final String label;
  final List<T> list;
  final T value;
  final ValueChanged<T> onChange;

  const SelectWidget({
    super.key,
    required this.list,
    required this.value,
    required this.onChange,
    required this.label,
  });

  @override
  State<SelectWidget> createState() => _SelectWidgetState<T>();
}

class _SelectWidgetState<T> extends State<SelectWidget<T>> {
  T? value;

  @override
  void initState() {
    value = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      label: Text(widget.label),
      initialSelection: value,
      onSelected: (T? value) {
        setState(() => this.value = value);
        widget.onChange(value as T);
      },
      dropdownMenuEntries: widget.list.map<DropdownMenuEntry<T>>(
            (T value) {
          return DropdownMenuEntry<T>(value: value, label: value.toString());
        },
      ).toList(),
    );
  }
}