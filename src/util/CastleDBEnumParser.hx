package util;

using ludi.commons.extensions.All;

class CastleDBEnumParser {
    private var config: EnumConfig;

    public function new(config: EnumConfig) {
        this.config = config;
    }

    public function parse(data: Array<Dynamic>, typeIndex: Int): EnumValue {
        var enumConfig = config.get(typeIndex);
        var enumType = enumConfig.e;
        var enumRefs = enumConfig.refs;
        
        var index = data[0];
        var args: Array<Dynamic> = [];
        
        for (i in 0...data.length - 1) {
            var rawArg = data[i + 1];

            // Check if the argument is a reference to another enum
            var ref = enumRefs.find((ref) -> {return (ref[0] == index && ref[1] == i);});
            if (ref != null) {
                var refTypeIndex = ref[2];
                var refData = rawArg;
                args.push(this.parse(refData, refTypeIndex));
            } else {
                args.push(rawArg);
            }
        }
        
        return enumType.createByIndex(index, args);
    }

    public function serialize(data: EnumValue, typeIndex: Int): Array<Dynamic> {
        var serialized: Array<Dynamic> = [];
        var enumConfig = config.get(typeIndex);
        var enumRefs = enumConfig.refs;
        var index = data.getIndex();
        serialized.push(index);
        var params = data.getParameters();
        
        for (i in 0...params.length) {
            var param = params[i];
            var ref = enumRefs.find((ref) -> {return (ref[0] == index && ref[1] == i);});
            if (ref != null) {
                var refTypeIndex = ref[2];
                serialized.push(this.serialize(param, refTypeIndex));
            } else {
                serialized.push(param);
            }
        }
        return serialized;
    }
}

typedef EnumConfig = Map<Int, {
    e: Enum<Dynamic>,
    refs: Array<EnumReferenceConfig>
}>;

typedef EnumReferenceConfig = Array<Int>;
//EnumReferenceConfig[0] = enum constructor index
//EnumReferenceConfig[1] = enum constructor param that is ref
//EnumReferenceConfig[2] = enum constructor param ref enum type index in EnumConfig