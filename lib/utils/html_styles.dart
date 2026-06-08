Map<String, String>? codeBlockStylesBuilder(dynamic element) {
  if (element.localName == 'pre') {
    return {
      'background-color': '#1e1e2e',
      'color': '#cdd6f4',
      'padding': '12px',
      'border-radius': '8px',
      'font-family': 'monospace',
      'overflow-x': 'auto',
    };
  }
  if (element.localName == 'code') {
    return {
      'background-color': element.parent?.localName == 'pre'
          ? 'transparent'
          : '#2a2a40',
      'color': '#f38ba8',
      'padding': '2px 4px',
      'border-radius': '4px',
      'font-family': 'monospace',
    };
  }
  return null;
}
