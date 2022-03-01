bool isSame<T0, T1>() {
    return T0.hashCode == T1.hashCode;
}

class VariantUtil {
    static String expectedMessage(List<String> typenames) {
        switch (typenames.length) {
        case 0: return '';
        case 1: return 'expected ${typenames[0]}';   
        case 2: return 'expected ${typenames[0]} or ${typenames[0]}';
        default: 
            String result = 'expected ';
            for (int i = 0; i < typenames.length; i++) {
                result += typenames[i];
                if (i == typenames.length - 2) { // is 
                    result += ', or ';
                }
                else if (i != typenames.length) {
                    result += ', ';
                }
            }
            return result;
        }
    }

    static bool isAnyOf<T>(List<int> typeHashCodes) {
        for (var hash in typeHashCodes) {
            if (T.hashCode == hash) return true;
        }
        return false;
    }
}

abstract class Variant {
    Variant construct(var value);
}

class Variant1<T> implements Variant {
    List<int>    get _typeHashes => [ T.hashCode   ];
    List<String> get _typeNames  => [ T.toString() ];
    // ignore: non_constant_identifier_names
    T? _0;
    
    @override
    Variant1 construct(var value) {
        assert(value is T);

        if (value is T) { _0 = value; }
        else {
            throw ArgumentError('value is the wrong type (${VariantUtil.expectedMessage(_typeNames)})');
        }
        return this;
    }

    Variant1(var value) {
        construct(value);
    }

    Variant1.ignore() : _0 = null;

    int get length => _typeHashes.length;

    bool _isTypeValid<Wanted>() {
        return VariantUtil.isAnyOf<Wanted>(_typeHashes);
    }

    int _getTypeIndex<Wanted>() {
        int hash = Wanted.hashCode;
        for (int i = 0; i < length; i++) {
            if (hash == _typeHashes[i]) return i;
        }
        return -1;
    }

    bool _isValue(int n) {
        return this[0] != null;
    }

    dynamic operator[](int index) {
        switch(index) {
        case 0: return _0;
        default: throw RangeError(index);
        }
    }
    
    bool isType<Wanted>() {
        if (!(_isTypeValid<Wanted>())) {
            throw ArgumentError('${Wanted.toString()} is the wrong type (${VariantUtil.expectedMessage(_typeNames)})');
        }
        
        int index = _getTypeIndex<Wanted>();
        return _isValue(index);
    }

    getValue<Wanted>() {
        if (!(_isTypeValid<Wanted>())) {
            throw ArgumentError('${Wanted.toString()} is the wrong type (${VariantUtil.expectedMessage(_typeNames)})');
        }
        
        int index = _getTypeIndex<Wanted>();
        if (this[index] == null) {
            throw Exception("the variant is not holding a value of type ${Wanted.toString()}");
        }
        return this[index]!;
    }
}

bool isPartOfVariantSet(dynamic value, Variant v) {
    try {
        v.construct(value);
        return true;
    } catch (error) {
        return false;
    }
}


class Variant2<T0, T1> extends Variant1 {
    @override
    List<int>    get _typeHashes => [ T0.hashCode, T1.hashCode, ];
    @override
    List<String> get _typeNames  => [ T0.toString(), T1.toString() ];

    // ignore: non_constant_identifier_names
    T1? _1;
    
    @override
    Variant2 construct(var value) {
        assert(value is T0 || value is T1);
        
        if (value is T1)      { _1 = value; }
        else if (value is T0) { _0 = value; }
        else { throw ArgumentError('value is the wrong type (${VariantUtil.expectedMessage(_typeNames)})'); }
        return this;
    }

    Variant2.ignore() : _1 = null, super.ignore();
    Variant2(var value) : super.ignore() { construct(value); }

    @override
    dynamic operator[](int index) {
        switch(index) {
        case 0: return _0;
        case 1: return _1;
        default: throw RangeError(index);
        }
    }
}
