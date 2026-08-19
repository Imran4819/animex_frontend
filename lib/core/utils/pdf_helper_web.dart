// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:js' as js;

void savePdfWeb(List<int> bytes, String invoiceId) {
  final base64String = base64Encode(bytes);
  final dataUrl = 'data:application/pdf;base64,$base64String';
  js.context.callMethod('eval', [
    '''
    var a = document.createElement('a');
    a.href = "$dataUrl";
    a.download = "invoice_$invoiceId.pdf";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    '''
  ]);
}
