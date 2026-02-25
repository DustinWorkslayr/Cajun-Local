/// Contact form template definitions (messaging-faqs-cheatsheet §5.3).
/// Keys must match DB: general_inquiry, appointment_request, quote_request, event_booking.
library;

class ContactFormFieldDef {
  const ContactFormFieldDef({
    required this.key,
    required this.label,
    this.type = ContactFormFieldType.text,
    this.required = true,
    this.hint,
  });
  final String key;
  final String label;
  final ContactFormFieldType type;
  final bool required;
  final String? hint;
}

enum ContactFormFieldType { text, email, phone, textarea, date }

class ContactFormTemplateDef {
  const ContactFormTemplateDef({
    required this.key,
    required this.name,
    required this.fields,
  });
  final String key;
  final String name;
  final List<ContactFormFieldDef> fields;
}

abstract class ContactFormTemplates {
  static const String generalInquiry = 'general_inquiry';
  static const String appointmentRequest = 'appointment_request';
  static const String quoteRequest = 'quote_request';
  static const String eventBooking = 'event_booking';

  static const List<String> allKeys = [
    generalInquiry,
    appointmentRequest,
    quoteRequest,
    eventBooking,
  ];

  static const List<ContactFormTemplateDef> templates = [
    ContactFormTemplateDef(
      key: generalInquiry,
      name: 'General inquiry',
      fields: [
        ContactFormFieldDef(key: 'name', label: 'Your name', type: ContactFormFieldType.text),
        ContactFormFieldDef(key: 'email', label: 'Email', type: ContactFormFieldType.email),
        ContactFormFieldDef(key: 'phone', label: 'Phone', type: ContactFormFieldType.phone, required: false),
        ContactFormFieldDef(key: 'message', label: 'Message', type: ContactFormFieldType.textarea),
      ],
    ),
    ContactFormTemplateDef(
      key: appointmentRequest,
      name: 'Appointment request',
      fields: [
        ContactFormFieldDef(key: 'name', label: 'Your name', type: ContactFormFieldType.text),
        ContactFormFieldDef(key: 'email', label: 'Email', type: ContactFormFieldType.email),
        ContactFormFieldDef(key: 'phone', label: 'Phone', type: ContactFormFieldType.phone),
        ContactFormFieldDef(key: 'preferred_date', label: 'Preferred date', type: ContactFormFieldType.date, hint: 'YYYY-MM-DD'),
        ContactFormFieldDef(key: 'notes', label: 'Notes', type: ContactFormFieldType.textarea, required: false),
      ],
    ),
    ContactFormTemplateDef(
      key: quoteRequest,
      name: 'Quote request',
      fields: [
        ContactFormFieldDef(key: 'name', label: 'Your name', type: ContactFormFieldType.text),
        ContactFormFieldDef(key: 'email', label: 'Email', type: ContactFormFieldType.email),
        ContactFormFieldDef(key: 'phone', label: 'Phone', type: ContactFormFieldType.phone),
        ContactFormFieldDef(key: 'description', label: 'Describe what you need', type: ContactFormFieldType.textarea),
      ],
    ),
    ContactFormTemplateDef(
      key: eventBooking,
      name: 'Event booking',
      fields: [
        ContactFormFieldDef(key: 'name', label: 'Your name', type: ContactFormFieldType.text),
        ContactFormFieldDef(key: 'email', label: 'Email', type: ContactFormFieldType.email),
        ContactFormFieldDef(key: 'phone', label: 'Phone', type: ContactFormFieldType.phone),
        ContactFormFieldDef(key: 'event_date', label: 'Event date', type: ContactFormFieldType.date, hint: 'YYYY-MM-DD'),
        ContactFormFieldDef(key: 'party_size', label: 'Party size / number of guests', type: ContactFormFieldType.text),
        ContactFormFieldDef(key: 'details', label: 'Additional details', type: ContactFormFieldType.textarea, required: false),
      ],
    ),
  ];

  static ContactFormTemplateDef? getByKey(String key) {
    try {
      return templates.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }
}
