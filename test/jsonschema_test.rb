require 'test/unit'
require 'open-uri'
require 'pp'
require File.dirname(__FILE__) + '/../lib/jsonschema'

class JSONSchemaTest < Test::Unit::TestCase
  def test_self_schema
    data1 = {
        "$schema" => {
            "properties" => {
                "name" => {
                    "type" => "string"
                },
                "age" => {
                    "type" => "integer",
                    "maximum" => 125,
                    "optional" => true
                }
            }
        },
        "name" => "John Doe",
        "age" => 30,
        "type" => "object"
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1)
    }
    data2 = {
        "$schema" => {
            "properties" => {
                "name" => {
                    "type" => "integer"
                },
                "age" => {
                    "type" => "integer",
                    "maximum" => 125,
                    "optional" => true
                }
            }
        },
        "name" => "John Doe",
        "age" => 30,
        "type" => "object"
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data2)
    }
    data3 = {
        "$schema" => {
            "properties" => {
                "name" => {
                    "type" => "integer"
                },
                "age" => {
                    "type" => "integer",
                    "maximum" => 125,
                    "optional" => true
                }
            }
        },
        "name" => "John Doe",
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3)
    }
  end

  def test_maximum
    schema1 = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "number",
                "maximum" => 10
            },
            "prop02" => {
                "type" => "integer",
                "maximum" => 20
            }
        }
    }
    data1 = {
        "prop01" => 5,
        "prop02" => 10
    }
    data2 = {
        "prop01" => 10,
        "prop02" => 20
    }
    data3 = {
        "prop01" => 11,
        "prop02" => 19
    }
    data4 = {
        "prop01" => 9,
        "prop02" => 21
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema1)
    }
    schema2 = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "number",
                "maximum" => 10,
                "maximumCanEqual" => true
            },
            "prop02" => {
                "type" => "integer",
                "maximum" => 20,
                "maximumCanEqual" => false
            }
        }
    }
    data5 = {
        "prop01" => 10,
        "prop02" => 10
    }
    data6 = {
        "prop01" => 10,
        "prop02" => 19
    }
    data7 = {
        "prop01" => 11,
        "prop02" => 19
    }
    data8 = {
        "prop01" => 9,
        "prop02" => 20
    }
    assert_nothing_raised {
      JSON::Schema.validate(data5, schema2)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data6, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data7, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data8, schema2)
    }
  end

  def test_extends
    schema = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "number",
                "minimum" => 10
            },
            "prop02" => {}
        }
    }
    schema["properties"]["prop02"]["extends"] = schema["properties"]["prop01"]
    data1 = {
        "prop01" => 21,
        "prop02" => 21
    }
    data2 = {
        "prop01" => 10,
        "prop02" => 20
    }
    data3 = {
        "prop01" => 9,
        "prop02" => 21
    }
    data4 = {
        "prop01" => 10,
        "prop02" => 9
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_minimum
    schema1 = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "number",
                "minimum" => 10
            },
            "prop02" => {
                "type" => "integer",
                "minimum" => 20
            }
        }
    }
    data1 = {
        "prop01" => 21,
        "prop02" => 21
    }
    data2 = {
        "prop01" => 10,
        "prop02" => 20
    }
    data3 = {
        "prop01" => 9,
        "prop02" => 21
    }
    data4 = {
        "prop01" => 10,
        "prop02" => 19
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema1)
    }
    schema2 = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "number",
                "minimum" => 10,
                "minimumCanEqual" => false
            },
            "prop02" => {
                "type" => "integer",
                "minimum" => 19,
                "minimumCanEqual" => true
            }
        }
    }
    data5 = {
        "prop01" => 11,
        "prop02" => 19
    }
    data6 = {
        "prop01" => 10,
        "prop02" => 19
    }
    data7 = {
        "prop01" => 11,
        "prop02" => 18
    }
    assert_nothing_raised {
      JSON::Schema.validate(data5, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data6, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data7, schema2)
    }
  end

  def test_minItems
    schema1 = {
        "type" => "array",
        "minItems" => 4
    }
    schema2 = {
        "minItems" => 4
    }
    data1 = [1, 2, "3", 4.0]
    data2 = [1, 2, "3", 4.0, 5.00]
    data3 = "test"
    data4 = [1, 2, "3"]
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema2)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema2)
    }
  end

  def test_maxItems
    schema1 = {
        "type" => "array",
        "maxItems" => 4
    }
    schema2 = {
        "maxItems" => 4
    }
    data1 = [1, 2, "3", 4.0]
    data2 = [1, 2, "3"]
    data3 = "test"
    data4 = [1, 2, "3", 4.0, 5.00]
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema2)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema2)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema2)
    }
  end

  def test_minLength
    schema = {
        "minLength" => 4
    }
    data1 = "test"
    data2 = "string"
    data3 = 123
    data4 = [1, 2, "3"]
    data5 = "car"
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data4, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data5, schema)
    }
  end

  def test_maxLength
    schema = {
        "maxLength" => 4
    }
    data1 = "test"
    data2 = "car"
    data3 = 12345
    data4 = [1, 2, "3", 4, 5]
    data5 = "string"
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data4, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data5, schema)
    }
  end

  def test_maxDecimal
    schema = {
        "type" => "number",
        "maxDecimal" => 3
    }
    data1 = 10.20
    data2 = 10.204
    data3 = 10
    data4 = 10.04092
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_properties
    schema = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "string",
            },
            "prop02" => {
                "type" => "number",
                "optional" => true
            },
            "prop03" => {
                "type" => "integer",
            },
            "prop04" => {
                "type" => "boolean",
            },
            "prop05" => {
                "type" => "object",
                "optional" => true,
                "properties" => {
                    "subprop01" => {
                        "type" => "string",
                    },
                    "subprop02" => {
                        "type" => "string",
                        "required" => true
                    }
                }
            }
        }
    }
    data1 = {
        "prop01" => "test",
        "prop02" => 1.20,
        "prop03" => 1,
        "prop04" => true,
        "prop05" => {
            "subprop01" => "test",
            "subprop02" => "test2"
        }
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    data2 = {
        "prop01" => "test",
        "prop02" => 1.20,
        "prop03" => 1,
        "prop04" => true
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    data3 = {
        "prop02" => 1.60,
        "prop05" => {
            "subprop01" => "test"
        }
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_title
    schema1 = {
        "title" => "My Title for My Schema"
    }
    schema2 = {
        "title" => 1233
    }
    data = "whatever"
    assert_nothing_raised {
      JSON::Schema.validate(data, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema2)
    }
  end

  def test_requires
    schema = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "string",
                "optional" => true
            },
            "prop02" => {
                "type" => "number",
                "optional" => true,
                "requires" => "prop01"
            }
        }
    }
    data1 = {}
    data2 = {
        "prop01" => "test",
        "prop02" => 2
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    data3 = {
        "prop02" => 2
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_pattern
    schema = {
        "pattern" => "^[A-Za-z0-9][A-Za-z0-9\.]*@([A-Za-z0-9]+\.)+[A-Za-z0-9]+$"
    }
    data1 = "my.email01@gmail.com"
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    data2 = 123
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema)
    }
    data3 = "whatever"
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_optional
    schema = {
        "type" => "object",
        "properties" => {
            "prop01" => {
                "type" => "string"
            },
            "prop02" => {
                "type" => "number",
                "required" => false
            },
            "prop03" => {
                "type" => "integer"
            },
            "prop04" => {
                "type" => "boolean",
                "required" => true
            }
        }
    }
    data1 = {
        "prop01" => "test",
        "prop03" => 1,
        "prop04" => false
    }
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema)
    }
    data2 = {
        "prop02" => "blah"
    }
    data3 = {
        "prop01" => "blah"
    }
    data4 = {
        "prop01" => "test",
        "prop03" => 1,
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data2, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_default
    schema1 = {
        "properties" => {
            "test" => {
                "optional" => true,
                "default" => 10
            },
        }
    }
    schema2 = {
        "properties" => {
            "test" => {
                "optional" => true,
                "default" => 10,
                "readonly" => true
            }
        }
    }
    data1 = {}
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_equal(10, data1["test"])

    data2 = {}
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema2)
    }
    assert_not_equal(10, data2["test"])

    data3 = {}
    assert_nothing_raised {
      JSON::Schema.validate(data3, schema1, {interactive: true})
    }
    assert_equal(10, data3["test"])

    data4 = {}
    assert_nothing_raised {
      JSON::Schema.validate(data4, schema1, {interactive: false})
    }
    assert_not_equal(10, data4["test"])
  end

  def test_description
    schema1 = {
        "description" => "My Description for My Schema"
    }
    schema2 = {
        "description" => 1233
    }
    data = "whatever"
    assert_nothing_raised {
      JSON::Schema.validate(data, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema2)
    }
  end

  def test_type
    # schema
    schema1 = {
        "type" => [
            {
                "type" => "array",
                "minItems" => 10
            },
            {
                "type" => "string",
                "pattern" => "^0+$"
            }
        ]
    }
    data1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    data2 = "0"
    data3 = 1203
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema1)
    }

    # integer phase
    [1, 89, 48, 32, 49, 42].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "integer"})
      }
    end
    [1.2, "bad", {"test" => "blah"}, [32, 49], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "integer"})
      }
    end

    # string phase
    ["surrender?", "nuts!", "ok", "@hsuha", "\'ok?\'", "blah"].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "string"})
      }
    end
    [1.2, 1, {"test" => "blah"}, [32, 49], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "string"})
      }
    end

    # number phase
    [1.2, 89.42, 48.5224242, 32, 49, 42.24324].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "number"})
      }
    end
    ["bad", {"test" => "blah"}, [32.42, 494242], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "number"})
      }
    end

    # boolean phase
    [true, false].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "boolean"})
      }
    end
    [1.2, "False", {"test" => "blah"}, [32, 49], 1, 0].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "boolean"})
      }
    end

    # object phase
    [{"blah" => "test"}, {"this" => {"blah" => "test"}}, {1 => 2, 10 => 20}].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "object"})
      }
    end
    [1.2, "bad", 123, [32, 49], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "object"})
      }
    end

    # array phase
    [[1, 89], [48, {"test" => "blah"}, "49", 42]].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "array"})
      }
    end
    [1.2, "bad", {"test" => "blah"}, 1234, true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "array"})
      }
    end

    # null phase
    assert_nothing_raised {
      JSON::Schema.validate(nil, {"type" => "null"})
    }
    [1.2, "bad", {"test" => "blah"}, [32, 49], 1284, true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"type" => "null"})
      }
    end

    # any phase
    [1.2, "bad", {"test" => "blah"}, [32, 49], nil, 1284, true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"type" => "any"})
      }
    end

  end

  def test_items
    schema1 = {
        "type" => "array",
        "items" => {
            "type" => "string"
        }
    }
    schema2 = {
        "type" => "array",
        "items" => [
            {"type" => "integer"},
            {"type" => "string"},
            {"type" => "boolean",
             "required" => "false"}
        ]
    }
    data1 = ["string", "another string", "mystring"]
    data2 = ["JSON Schema is cool", "yet another string"]
    assert_nothing_raised {
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data2, schema1)
    }
    data3 = ["string", "another string", 1]
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data3, schema1)
    }
    data4 = [1, "More strings?", true]
    data5 = [12482, "Yes, more strings", false]
    assert_nothing_raised {
      JSON::Schema.validate(data4, schema2)
    }
    assert_nothing_raised {
      JSON::Schema.validate(data5, schema2)
    }
    data6 = [1294, "Ok. I give up"]
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data6, schema2)
    }
    data7 = [1294, "Ok. I give up", "Not a boolean"]
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data7, schema2)
    }
  end

  def test_enum
    schema = {
        "enum" => ["test", true, 123, ["???"]]
    }
    ["test", true, 123, ["???"]].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, schema)
      }
    end
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate("unknown", schema)
    }
  end


  def test_additionalProperties
    schema1 = {
        "additionalProperties" => {
            "type" => "integer"
        }
    }
    [1, 89, 48, 32, 49, 42].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate({"prop" => item}, schema1)
      }
    end
    [1.2, "bad", {"test" => "blah"}, [32, 49], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate({"prop" => item}, schema1)
      }
    end
    schema2 = {
        "properties" => {
            "prop1" => {"type" => "integer"},
            "prop2" => {"type" => "string"}
        },
        "additionalProperties" => {
            "type" => ["string", "number"]
        }
    }
    [1, "test", 48, "ok", 4.9, 42].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate({
                                  "prop1" => 123,
                                  "prop2" => "this is prop2",
                                  "prop3" => item
                              }, schema2)
      }
    end
    [{"test" => "blah"}, [32, 49], true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate({
                                  "prop1" => 123,
                                  "prop2" => "this is prop2",
                                  "prop3" => item
                              }, schema2)
      }
    end
    schema3 = {
        "additionalProperties" => true
    }
    [1.2].each do |item|
      JSON::Schema.validate({"prop" => item}, schema3)
    end
    schema4 = {
        "additionalProperties" => false
    }
    ["bad", {"test" => "blah"}, [32.42, 494242], nil, true, 1.34].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate({"prop" => item}, schema4)
      }
    end
  end

  def test_disallow
    # multi phase
    schema = {"disallow" => ["null", "integer", "string"]}
    [nil, 183, "mystring"].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, schema)
      }
    end
    [1.2, {"test" => "blah"}, [32, 49], true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, schema)
      }
    end

    # any phase
    [1.2, "bad", {"test" => "blah"}, [32, 49], nil, 1284, true].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "any"})
      }
    end

    # null phase
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(nil, {"disallow" => "null"})
    }
    [1.2, "bad", {"test" => "blah"}, [32, 49], 1284, true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "null"})
      }
    end

    # array phase
    [[1, 89], [48, {"test" => "blah"}, "49", 42]].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "array"})
      }
    end
    [1.2, "bad", {"test" => "blah"}, 1234, true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "array"})
      }
    end

    # object phase
    [{"blah" => "test"}, {"this" => {"blah" => "test"}}, {1 => 2, 10 => 20}].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "object"})
      }
    end
    [1.2, "bad", 123, [32, 49], true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "object"})
      }
    end

    # boolean phase
    [true, false].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "boolean"})
      }
    end
    [1.2, "False", {"test" => "blah"}, [32, 49], 1, 0].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "boolean"})
      }
    end

    # number phase
    [1.2, 89.42, 48.5224242, 32, 49, 42.24324].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "number"})
      }
    end
    ["bad", {"test" => "blah"}, [32.42, 494242], true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "number"})
      }
    end

    # integer phase
    [1, 89, 48, 32, 49, 42].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "integer"})
      }
    end
    [1.2, "bad", {"test" => "blah"}, [32, 49], true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "integer"})
      }
    end

    # string phase
    ["surrender?", "nuts!", "ok", "@hsuha", "\'ok?\'", "blah"].each do |item|
      assert_raise(JSON::Schema::ValueError) {
        JSON::Schema.validate(item, {"disallow" => "string"})
      }
    end
    [1.2, 1, {"test" => "blah"}, [32, 49], true].each do |item|
      assert_nothing_raised {
        JSON::Schema.validate(item, {"disallow" => "string"})
      }
    end
  end

  def test_additional_properties_param_for_plain_obj
    schema = {
        "properties" => {
            "prop1" => {"type" => "integer"},
            "prop2" => {"type" => "string"}
        }
    }

    data = {
        "prop1" => 123,
        "prop2" => "this is prop2",
        "prop3" => 'item'
    }
    #happy_path
    assert_nothing_raised {
      JSON::Schema.validate(data, schema)
    }
    #should_raise_error
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema, {additional_properties: false})
    }
  end

  def test_additional_properties_param_for_array
    schema = {
        "properties" => {"roles" => {

            "type" => "array",
            "items" => {
                "type" => "object",
                "properties" => {
                    "id" => {
                        "type" => "integer"
                    },
                    "roleName" => {
                        "type" => "string"
                    }
                }
            }
        }}
    }

    data ={"roles" => [
        {
            "id" => 2,
            "roleName" => "Buyer",
            "contactPerson" => "Marco"
        }
    ]}
    #happy_path
    assert_nothing_raised {
      JSON::Schema.validate(data, schema)
    }
    #should_raise_error
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema, {additional_properties: false})
    }
  end

  def test_additional_properties_param_for_nested_obj
    schema = {
        "properties" => {"roles" => {

            "type" => "object",
            "items" => {
                "type" => "object",
                "properties" => {
                    "id" => {
                        "type" => "integer"
                    },
                    "roleName" => {
                        "type" => "string"
                    }
                }
            }
        }}
    }

    data ={"roles" =>
               {
                   "id" => 2,
                   "roleName" => "Buyer",
                   "contactPerson" => "Marco"
               }
    }
    #happy_path
    # assert_nothing_raised {
    #   JSON::Schema.validate(data, schema)
    # }
    #should_raise_error
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema, {additional_properties: false})
    }
  end

  def test_additional_properties_for_array_obj
    schema = {"type" => "array",
              "items" => {
                  "type" => "object",
                  "properties" => {
                      "count" => {
                          "type" => "integer"
                      },
                      "mode" => {
                          "type" => "string"
                      }
                  }
              }
    }
    data = [{"count" => 6, "mode" => "central", "contactPerson" => "Marco"}, {"count" => 7, "mode" => "direct"}, {"count" => 9, "mode" => "mixed"}]
    #happy_path
    assert_nothing_raised {
      JSON::Schema.validate(data, schema)
    }
    #should_raise_error
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema, {additional_properties: false})
    }
  end

  def test_end_to_end
    schema = {"type" => "array",
              "items" =>
                  {"type" => "object",
                   "properties" =>
                       {"id" => {"type" => "integer"},
                        "lastName" => {"type" => "string"},
                        "subCategories" =>
                            {"type" => "array",
                             "items" =>
                                 {"type" => "object",
                                  "properties" =>
                                      {"id" => {"type" => "integer"}, "name" => {"type" => "string"}}}},
                        "email" => {"type" => "string"},
                        "roles" =>
                            {"type" => "array",
                             "items" =>
                                 {"type" => "object",
                                  "properties" =>
                                      {"id" => {"type" => "integer"}, "roleName" => {"type" => "string"}}}},
                        "userId" => {"type" => "string"},
                        "firstName" => {"type" => "string"}}}}

    data =[{
               "id" => 51,
               "roles" => [{"id" => 2, "roleName" => "Buyer"}],
               "subCategories" =>
                   [{"name" => "GRAPPE", "id" => 1001},
                    {"name" => "WHISKY", "id" => 1002},
                    {"name" => "LIQUORI", "id" => 1005},
                    {"name" => "CAFFE'", "id" => 7001},
                    {"name" => "CEREALI", "id" => 8001},
                    {"name" => "MERENDE E TORTE", "id" => 8003},
                    {"name" => "BISCOTTI", "id" => 8004},
                    {"name" => "DOLCE", "id" => 9001},
                    {"name" => "SNACK DOLCI", "id" => 10005},
                    {"name" => "PASTA", "id" => 13001}],
               "userId" => "MARDEGAN",
               "firstName" => "Massimiliano",
               "lastName" => "Mardegan",
               "email" => "Massimiliano_Mardegan@gruppopam.it",
               "con" => 2}]
    #happy_path
    assert_nothing_raised {
      JSON::Schema.validate(data, schema)
    }
    #should_raise_error
    assert_raise(JSON::Schema::ValueError) {
      JSON::Schema.validate(data, schema, {additional_properties: false})
    }
  end

  def test_for_hash

    schema = {
        "type" => "object",
        "properties" => {
            "warn" => {
                "type" => "object",
                "additional_properties" => {
                    "type" => "array"
                }
            },
            "error" => {
                "type" => "object",
                "additional_properties" => {
                    "type" => "array"
                }
            },
            "articles" => {
                "type" => "array",
                "items" => {
                    "type" => "object",
                    "properties" => {
                        "cluster" => {
                            "type" => "string"
                        },
                        "category_name" => {
                            "type" => "string"
                        },
                        "operational_status" => {
                            "type" => "string"
                        },
                        "is_out_of_invoice_extra_contractual_per_piece_discount_value" => {
                            "type" => "boolean"
                        },
                        "promo_mechanic_value_id" => {
                            "type" => "integer"
                        },
                        "store_group_ids" => {
                            "type" => "array",
                            "items" => {
                                "type" => "integer"
                            }
                        },
                        "toscana_promo_price" => {
                            "type" => "number"
                        },
                        "pieces_per_package" => {
                            "type" => "integer"
                        },
                        "inactive" => {
                            "type" => "boolean"
                        },
                        "out_of_invoice_extra_contractual_per_piece_discount" => {
                            "type" => "number"
                        },
                        "replenishments" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "replenishment_type" => {
                                        "type" => "string"
                                    },
                                    "store_group_id" => {
                                        "type" => "integer"
                                    }
                                }
                            }
                        },
                        "simulated_speculative_discount" => {
                            "type" => "number"
                        },
                        "sub_category_name" => {
                            "type" => "string"
                        },
                        "non_ideal_net_net_cost" => {
                            "type" => "number"
                        },
                        "ordered_by_assistant_notes" => {
                            "type" => "string"
                        },
                        "vat" => {
                            "type" => "number"
                        },
                        "simulated_canvass_discount" => {
                            "type" => "number"
                        },
                        "non_ideal_net_cost" => {
                            "type" => "number"
                        },
                        "buyer" => {
                            "type" => "string"
                        },
                        "finalized" => {
                            "type" => "boolean"
                        },
                        "aggregate_promotional_discount" => {
                            "type" => "number"
                        },
                        "handling_cost" => {
                            "type" => "number"
                        },
                        "similar_articles" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "category_name" => {
                                        "type" => "string"
                                    },
                                    "representative_article_id" => {
                                        "type" => "integer"
                                    },
                                    "similar_article_id" => {
                                        "type" => "integer"
                                    },
                                    "article_weight" => {
                                        "type" => "integer"
                                    },
                                    "article_unit" => {
                                        "type" => "string"
                                    },
                                    "non_removable" => {
                                        "type" => "boolean"
                                    },
                                    "geco_status" => {
                                        "type" => "string"
                                    },
                                    "category_id" => {
                                        "type" => "integer"
                                    },
                                    "sub_category_id" => {
                                        "type" => "integer"
                                    },
                                    "name" => {
                                        "type" => "string"
                                    },
                                    "sub_category_name" => {
                                        "type" => "string"
                                    },
                                    "workbook_id" => {
                                        "type" => "string"
                                    },
                                    "sub_family_id" => {
                                        "type" => "integer"
                                    },
                                    "sub_family_name" => {
                                        "type" => "string"
                                    },
                                    "supplier_name" => {
                                        "type" => "string"
                                    },
                                    "supplier_id" => {
                                        "type" => "integer"
                                    }
                                }
                            }
                        },
                        "margin_value" => {
                            "type" => "number"
                        },
                        "tipo_off" => {
                            "type" => "string"
                        },
                        "promo_mechanic_id" => {
                            "type" => "integer"
                        },
                        "margin_percentage" => {
                            "type" => "number"
                        },
                        "excise" => {
                            "type" => "number"
                        },
                        "created_at" => {
                            "type" => "string"
                        },
                        "resolved_store_group_ids" => {
                            "type" => "array",
                            "items" => {
                                "type" => "integer"
                            }
                        },
                        "cost_and_discounts" => {
                            "type" => "object",
                            "properties" => {
                                "gross_cost" => {
                                    "type" => "number"
                                },
                                "invoice_net_cost" => {
                                    "type" => "number"
                                },
                                "favourable_discount_type" => {
                                    "type" => "string"
                                },
                                "discounts_evaluated" => {
                                    "type" => "array",
                                    "items" => {
                                        "type" => "object",
                                        "properties" => {
                                            "discount_details" => {
                                                "type" => "array",
                                                "items" => {
                                                    "type" => "object",
                                                    "properties" => {
                                                        "paid_quantity" => {
                                                            "type" => "integer"
                                                        },
                                                        "discount_code" => {
                                                            "type" => "object",
                                                            "properties" => {
                                                                "code" => {
                                                                    "type" => "string"
                                                                },
                                                                "description" => {
                                                                    "type" => "string"
                                                                }
                                                            }
                                                        },
                                                        "percentage" => {
                                                            "type" => "number"
                                                        },
                                                        "value" => {
                                                            "type" => "number"
                                                        },
                                                        "free_quantity" => {
                                                            "type" => "integer"
                                                        }
                                                    }
                                                }
                                            },
                                            "discount_type" => {
                                                "type" => "object",
                                                "properties" => {
                                                    "description" => {
                                                        "type" => "string"
                                                    },
                                                    "type" => {
                                                        "type" => "string"
                                                    }
                                                }
                                            },
                                            "aggregated_discount" => {
                                                "type" => "number"
                                            }
                                        }
                                    }
                                },
                                "excluded_discounts" => {
                                    "type" => "array",
                                    "items" => {
                                        "type" => "object",
                                        "properties" => {
                                            "discount_details" => {
                                                "type" => "array",
                                                "items" => {
                                                    "type" => "object",
                                                    "properties" => {
                                                        "paid_quantity" => {
                                                            "type" => "integer"
                                                        },
                                                        "discount_code" => {
                                                            "type" => "object",
                                                            "properties" => {
                                                                "code" => {
                                                                    "type" => "string"
                                                                },
                                                                "description" => {
                                                                    "type" => "string"
                                                                }
                                                            }
                                                        },
                                                        "percentage" => {
                                                            "type" => "number"
                                                        },
                                                        "value" => {
                                                            "type" => "number"
                                                        },
                                                        "free_quantity" => {
                                                            "type" => "integer"
                                                        }
                                                    }
                                                }
                                            },
                                            "discount_type" => {
                                                "type" => "object",
                                                "properties" => {
                                                    "description" => {
                                                        "type" => "string"
                                                    },
                                                    "type" => {
                                                        "type" => "string"
                                                    }
                                                }
                                            },
                                            "aggregated_discount" => {
                                                "type" => "number"
                                            }
                                        }
                                    }
                                },
                                "entity_id" => {
                                    "type" => "integer"
                                },
                                "net_cost" => {
                                    "type" => "number"
                                },
                                "out_invoice_discount" => {
                                    "type" => "object",
                                    "properties" => {
                                        "out_of_invoice_percent" => {
                                            "type" => "number"
                                        },
                                        "end_of_year_percent" => {
                                            "type" => "number"
                                        }
                                    }
                                },
                                "net_net_cost" => {
                                    "type" => "number"
                                },
                                "supplier_cost_corrections" => {
                                    "type" => "array",
                                    "items" => {
                                        "type" => "object",
                                        "properties" => {
                                            "percentage" => {
                                                "type" => "number"
                                            },
                                            "value" => {
                                                "type" => "number"
                                            },
                                            "cost_correction_code" => {
                                                "type" => "object",
                                                "properties" => {
                                                    "code" => {
                                                        "type" => "string"
                                                    },
                                                    "description" => {
                                                        "type" => "string"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        "gross_cost" => {
                            "type" => "number"
                        },
                        "geco_status" => {
                            "type" => "string"
                        },
                        "category_id" => {
                            "type" => "integer"
                        },
                        "sale_value_excluding_vat" => {
                            "type" => "number"
                        },
                        "sub_family_id" => {
                            "type" => "integer"
                        },
                        "replenishment_changed" => {
                            "type" => "boolean"
                        },
                        "supplier_name" => {
                            "type" => "string"
                        },
                        "massification" => {
                            "type" => "string"
                        },
                        "article_type" => {
                            "type" => "string"
                        },
                        "department_id" => {
                            "type" => "integer"
                        },
                        "simulated_promo_discount1" => {
                            "type" => "number"
                        },
                        "max_price" => {
                            "type" => "number"
                        },
                        "simulated_promo_discount2" => {
                            "type" => "number"
                        },
                        "dc_id" => {
                            "type" => "integer"
                        },
                        "toscana_starting_price" => {
                            "type" => "number"
                        },
                        "sub_family_name" => {
                            "type" => "string"
                        },
                        "non_ideal_promo_discount_final" => {
                            "type" => "number"
                        },
                        "operational_errors" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "error_message" => {
                                        "type" => "string"
                                    },
                                    "is_similar_article" => {
                                        "type" => "boolean"
                                    }
                                }
                            }
                        },
                        "in_invoice_contractual_discounts" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "discount_details" => {
                                        "type" => "array",
                                        "items" => {
                                            "type" => "object",
                                            "properties" => {
                                                "paid_quantity" => {
                                                    "type" => "integer"
                                                },
                                                "discount_code" => {
                                                    "type" => "object",
                                                    "properties" => {
                                                        "code" => {
                                                            "type" => "string"
                                                        },
                                                        "description" => {
                                                            "type" => "string"
                                                        }
                                                    }
                                                },
                                                "percentage" => {
                                                    "type" => "number"
                                                },
                                                "value" => {
                                                    "type" => "number"
                                                },
                                                "free_quantity" => {
                                                    "type" => "integer"
                                                }
                                            }
                                        }
                                    },
                                    "discount_type" => {
                                        "type" => "object",
                                        "properties" => {
                                            "description" => {
                                                "type" => "string"
                                            },
                                            "type" => {
                                                "type" => "string"
                                            }
                                        }
                                    },
                                    "aggregated_discount" => {
                                        "type" => "number"
                                    }
                                }
                            }
                        },
                        "sell_in_start_date" => {
                            "type" => "integer",
                            "format" => "UTC_MILLISEC"
                        },
                        "promo_discount_final" => {
                            "type" => "number"
                        },
                        "notes" => {
                            "type" => "string"
                        },
                        "promo_price" => {
                            "type" => "number"
                        },
                        "expected_pieces" => {
                            "type" => "integer"
                        },
                        "expected_packages" => {
                            "type" => "number"
                        },
                        "sell_in_end_date" => {
                            "type" => "integer",
                            "format" => "UTC_MILLISEC"
                        },
                        "mode_price" => {
                            "type" => "number"
                        },
                        "workbook_id" => {
                            "type" => "string"
                        },
                        "aggregate_speculative_discount" => {
                            "type" => "number"
                        },
                        "beneficiaries" => {
                            "type" => "array",
                            "items" => {
                                "type" => "integer"
                            }
                        },
                        "non_ideal_invoice_net_cost" => {
                            "type" => "number"
                        },
                        "sync_to_gas" => {
                            "type" => "boolean"
                        },
                        "new_article" => {
                            "type" => "boolean"
                        },
                        "visibility" => {
                            "type" => "string"
                        },
                        "resolved_toscana_store_group_ids" => {
                            "type" => "array",
                            "items" => {
                                "type" => "integer"
                            }
                        },
                        "price_point_type" => {
                            "type" => "string"
                        },
                        "article_unit" => {
                            "type" => "string"
                        },
                        "created_by" => {
                            "type" => "string"
                        },
                        "tipo_off_fidelity" => {
                            "type" => "string"
                        },
                        "name" => {
                            "type" => "string"
                        },
                        "aggregate_canvass_discount" => {
                            "type" => "number"
                        },
                        "supplier_id" => {
                            "type" => "integer"
                        },
                        "transportation_cost" => {
                            "type" => "number"
                        },
                        "net_net_cost" => {
                            "type" => "number"
                        },
                        "mandatory_beneficiaries" => {
                            "type" => "array",
                            "items" => {
                                "type" => "integer"
                            }
                        },
                        "invoice_net_cost" => {
                            "type" => "number"
                        },
                        "geco_failure_reason" => {
                            "type" => "string"
                        },
                        "simulation_price" => {
                            "type" => "number"
                        },
                        "similars_count" => {
                            "type" => "integer"
                        },
                        "fidelity" => {
                            "type" => "boolean"
                        },
                        "non_ideal_margin_value" => {
                            "type" => "number"
                        },
                        "article_id" => {
                            "type" => "integer"
                        },
                        "sync_to_gas_action" => {
                            "type" => "string"
                        },
                        "starting_price" => {
                            "type" => "number"
                        },
                        "sub_category_id" => {
                            "type" => "integer"
                        },
                        "honor_gamma_structure" => {
                            "type" => "boolean"
                        },
                        "net_cost" => {
                            "type" => "number"
                        },
                        "non_ideal_margin_percentage" => {
                            "type" => "number"
                        },
                        "ordered_by_assistant" => {
                            "type" => "boolean"
                        },
                        "non_returnable_on_promo" => {
                            "type" => "boolean"
                        },
                        "effective_beneficiaries" => {
                            "type" => "array",
                            "items" => {
                                "type" => "string"
                            }
                        },
                        "was_already_sent_to_gas" => {
                            "type" => "boolean"
                        },
                        "article_weight" => {
                            "type" => "integer"
                        },
                        "supplier_cost_corrections" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "percentage" => {
                                        "type" => "number"
                                    },
                                    "value" => {
                                        "type" => "number"
                                    },
                                    "cost_correction_code" => {
                                        "type" => "object",
                                        "properties" => {
                                            "code" => {
                                                "type" => "string"
                                            },
                                            "description" => {
                                                "type" => "string"
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        "sale_value" => {
                            "type" => "number"
                        },
                        "promo_mechanic_description" => {
                            "type" => "string"
                        },
                        "store_booking_required" => {
                            "type" => "boolean"
                        },
                        "min_price" => {
                            "type" => "number"
                        },
                        "group_id" => {
                            "type" => "integer"
                        },
                        "out_invoice_discounts" => {
                            "type" => "object",
                            "properties" => {
                                "out_of_invoice_percent" => {
                                    "type" => "number"
                                },
                                "end_of_year_percent" => {
                                    "type" => "number"
                                }
                            }
                        },
                        "extend_assortment" => {
                            "type" => "boolean"
                        },
                        "validation_errors" => {
                            "type" => "array",
                            "items" => {
                                "type" => "object",
                                "properties" => {
                                    "error_message" => {
                                        "type" => "string"
                                    },
                                    "error_type" => {
                                        "type" => "string"
                                    },
                                    "error_field" => {
                                        "type" => "string"
                                    }
                                }
                            }
                        },
                        "merchandise_type" => {
                            "type" => "string"
                        }
                    }
                }
            },
            "info" => {
                "type" => "object",
                "additional_properties" => {
                    "type" => "integer"
                }
            }
        }
    }

    data = {
        "info" => {
            "total_articles" => 0,
            "similars_added" => 0,
            "articles_added" => 0,
            "articles_not_added" => 1
        },
        "articles" => []
    }

    JSON::Schema.validate(data, schema, {additional_properties: false})

  end
end

