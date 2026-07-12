double jsonToDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

double? jsonToDoubleN(dynamic v) => (v as num?)?.toDouble();

Map<String, double> jsonToDoubleMap(dynamic map) =>
    (map as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0)) ??
    {};
