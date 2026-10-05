import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PriceRangeSelector extends StatefulWidget {
  const PriceRangeSelector({super.key, required this.onChanged});

  final ValueChanged<int?> onChanged;

  @override
  State<PriceRangeSelector> createState() => _PriceRangeSelectorState();
}

class _PriceRangeSelectorState extends State<PriceRangeSelector> {
  static const amounts = [200, 500, 1000, 2000, 3000, 5000];
  final controller = TextEditingController(text: '500');
  double sliderPosition = 1;
  bool unlimited = false;
  bool manualMode = false;

  void changeMode(bool manual) {
    FocusScope.of(context).unfocus();
    setState(() {
      manualMode = manual;
      if (manual) {
        if (unlimited) controller.text = '5000';
        unlimited = false;
      } else {
        final index = sliderPosition.round();
        unlimited = index == 6;
        controller.text = unlimited ? '' : '${amounts[index]}';
      }
    });
    widget.onChanged(unlimited ? null : int.tryParse(controller.text) ?? 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String formatAmount(int amount) => amount >= 1000
      ? '${amount ~/ 1000},${(amount % 1000).toString().padLeft(3, '0')}'
      : '$amount';

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(controller.text);
    final label = unlimited
        ? '₹5,000+'
        : amount == null
        ? 'Enter an amount'
        : 'Up to ₹${formatAmount(amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set price range',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E7DC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _modeButton('Slider', Icons.tune_rounded, false),
              const SizedBox(width: 6),
              _modeButton('Manual', Icons.edit_outlined, true),
            ],
          ),
        ),
        if (!manualMode)
          Slider(
            key: const Key('price-slider'),
            value: sliderPosition,
            min: 0,
            max: 6,
            divisions: 6,
            label: label,
            onChanged: manualMode
                ? null
                : (value) {
                    final index = value.round();
                    setState(() {
                      sliderPosition = value;
                      unlimited = index == 6;
                      controller.text = unlimited ? '' : '${amounts[index]}';
                    });
                    widget.onChanged(unlimited ? null : amounts[index]);
                  },
          ),
        if (manualMode) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('manual-price-field'),
            enabled: manualMode,
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              labelText: 'Manual budget per person',
              prefixText: '₹ ',
              hintText: unlimited ? 'No upper limit' : 'Enter amount',
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (!manualMode) return null;
              final budget = int.tryParse(value ?? '');
              return budget == null || budget < 1
                  ? 'Enter an amount greater than zero'
                  : null;
            },
            onChanged: (value) {
              final budget = int.tryParse(value);
              setState(() {
                unlimited = false;
                if (budget != null) {
                  var closest = 0;
                  for (var i = 1; i < amounts.length; i++) {
                    if ((amounts[i] - budget).abs() <
                        (amounts[closest] - budget).abs()) {
                      closest = i;
                    }
                  }
                  sliderPosition = closest.toDouble();
                }
              });
              widget.onChanged(budget ?? 0);
            },
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Budget per person, shared equally. Actual menu prices and your final bill may vary. ₹5,000+ means no upper limit.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _modeButton(String title, IconData icon, bool manual) {
    final selected = manualMode == manual;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: TextButton.icon(
          onPressed: () => changeMode(manual),
          icon: Icon(icon, size: 18),
          label: Text(title),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            backgroundColor: selected
                ? const Color(0xFFE94F54)
                : Colors.transparent,
            foregroundColor: selected ? Colors.white : const Color(0xFF795C53),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
    );
  }
}
