
// class _PaymentTile extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final String value;
//   final String groupValue;
//   final ValueChanged<String?> onChanged;

//   const _PaymentTile({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.value,
//     required this.groupValue,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return RadioListTile<String>(
//       value: value,
//       groupValue: groupValue,
//       onChanged: onChanged,
//       title: Row(
//         children: [
//           Icon(
//             icon,
//             size: 20,
//             color: Theme.of(context).colorScheme.onSurfaceVariant,
//           ),
//           const SizedBox(width: 12),
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         ],
//       ),
//       subtitle: Padding(
//         padding: const EdgeInsets.only(left: 32.0),
//         child: Text(subtitle, style: const TextStyle(fontSize: 12)),
//       ),
//       controlAffinity: ListTileControlAffinity.trailing,
//     );
//   }
// }

// class _BillRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isTotal;
//   final bool highlight;
//   final Color? color;

//   const _BillRow({
//     required this.label,
//     required this.value,
//     this.isTotal = false,
//     this.highlight = false,
//     this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: isTotal
//               ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
//               : textTheme.bodyMedium?.copyWith(
//                   color: highlight
//                       ? Theme.of(context).colorScheme.primary
//                       : Theme.of(
//                           context,
//                         ).colorScheme.onSurface.withOpacity(0.7),
//                 ),
//         ),
//         Text(
//           value,
//           style: isTotal
//               ? textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 )
//               : textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: highlight
//                       ? Theme.of(context).colorScheme.primary
//                       : null,
//                 ),
//         ),
//       ],
//     );
//   }
// }
