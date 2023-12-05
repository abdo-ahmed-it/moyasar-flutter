import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';
import 'package:moyasar/src/utils/card_utils.dart';
import 'package:moyasar/src/utils/input_formatters.dart';
import 'package:moyasar/src/widgets/network_icons.dart';

/// The widget that shows the Credit Card form and manages the 3DS step.
class CreditCard extends StatefulWidget {
  const CreditCard({
    super.key,
    this.locale = const Localization.en(),
    required this.onValidate,
    this.saveCard,
    required this.amount,
  });
  final num amount;
  final Function(CardFormModel) onValidate;
  final bool? saveCard;
  final Localization locale;

  @override
  State<CreditCard> createState() => _SimpleCreditCardState();
}

class _SimpleCreditCardState extends State<CreditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final CardFormModel _cardData = CardFormModel();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  bool _tokenizeCard = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _tokenizeCard = widget.saveCard ?? false;
    });
  }

  void _saveForm() async {
    closeKeyboard();
    bool isValidForm = _formKey.currentState != null && _formKey.currentState!.validate();
    if (!isValidForm) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    _formKey.currentState?.save();
    widget.onValidate(_cardData);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: _autoValidateMode,
      key: _formKey,
      child: Column(
        children: [
          CardFormField(
              inputDecoration: buildInputDecoration(
                hintText: widget.locale.nameOnCard,
              ),
              keyboardType: TextInputType.text,
              validator: (String? input) => CardUtils.validateName(input, widget.locale),
              onSaved: (value) => _cardData.name = value ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z. ]')),
              ]),
          CardFormField(
            inputDecoration: buildInputDecoration(hintText: widget.locale.cardNumber, addNetworkIcons: true),
            validator: (String? input) => CardUtils.validateCardNum(input, widget.locale),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter(),
            ],
            onSaved: (value) => _cardData.number = CardUtils.getCleanedNumber(value!),
          ),
          CardFormField(
            inputDecoration: buildInputDecoration(
              hintText: '${widget.locale.expiry} (MM / YY)',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
              CardMonthInputFormatter(),
            ],
            validator: (String? input) => CardUtils.validateDate(input, widget.locale),
            onSaved: (value) {
              List<String> expireDate = CardUtils.getExpiryDate(value!);
              _cardData.month = expireDate.first;
              _cardData.year = expireDate[1];
            },
          ),
          CardFormField(
            inputDecoration: buildInputDecoration(
              hintText: widget.locale.cvc,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (String? input) => CardUtils.validateCVC(input, widget.locale),
            onSaved: (value) => _cardData.cvc = value ?? '',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              child: ElevatedButton(
                style: ButtonStyle(
                  minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(55)),
                  backgroundColor: MaterialStatePropertyAll<Color>(blueColor),
                ),
                onPressed: _saveForm,
                child: Text(showAmount(widget.amount, widget.locale), style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
          SaveCardNotice(tokenizeCard: _tokenizeCard, locale: widget.locale)
        ],
      ),
    );
  }
}

class SaveCardNotice extends StatelessWidget {
  const SaveCardNotice({super.key, required this.tokenizeCard, required this.locale});

  final bool tokenizeCard;
  final Localization locale;

  @override
  Widget build(BuildContext context) {
    return tokenizeCard
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.info,
                  color: blueColor,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                ),
                Text(
                  locale.saveCardNotice,
                  style: TextStyle(color: blueColor),
                ),
              ],
            ))
        : const SizedBox.shrink();
  }
}

class CardFormField extends StatelessWidget {
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? inputDecoration;

  const CardFormField({
    super.key,
    required this.onSaved,
    this.validator,
    this.inputDecoration,
    this.keyboardType = TextInputType.number,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: inputDecoration,
          validator: validator,
          onSaved: onSaved,
          inputFormatters: inputFormatters),
    );
  }
}

String showAmount(num amount, Localization locale) {
  final String formattedAmount = amount.toStringAsFixed(2);

  if (locale.languageCode == 'en') {
    return '${locale.pay} SAR $formattedAmount';
  }

  return '${locale.pay} $formattedAmount ر.س';
}

InputDecoration buildInputDecoration({required String hintText, bool addNetworkIcons = false}) {
  return InputDecoration(
      suffixIcon: addNetworkIcons ? const NetworkIcons() : null,
      hintText: hintText,
      focusedErrorBorder: defaultErrorBorder,
      enabledBorder: defaultEnabledBorder,
      focusedBorder: defaultFocusedBorder,
      errorBorder: defaultErrorBorder,
      contentPadding: const EdgeInsets.all(8.0));
}

void closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

BorderRadius defaultBorderRadius = const BorderRadius.all(Radius.circular(8));

OutlineInputBorder defaultEnabledBorder = OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: defaultBorderRadius);

OutlineInputBorder defaultFocusedBorder = OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!), borderRadius: defaultBorderRadius);

OutlineInputBorder defaultErrorBorder = OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: defaultBorderRadius);

Color blueColor = Colors.blue[700]!;
