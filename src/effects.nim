const
  HDisplacement* = """
    uniform float time;

    float rand(vec2 co) {
      float a = 12.9898;
      float b = 78.233;
      float c = 43758.5453;
      float dt = dot(co.xy, vec2(a, b));
      float sn = mod(dt, 3.14);
      return fract(sin(sn) * c);
    }

    vec4 get(vec2 pos, float offset) {
      return rPixel(pos + vec2(rand(pos + time), mod(time, 1.0) + offset));
    }

    vec4 rEffect(vec2 pos) {
      return vec4(get(pos, 0.0).r,
                  get(pos + vec2(mod(time, 0.2323) * 10.0, 0.0), 1.0).g,
                  get(pos, 2.0 + mod(time, 0.77) * 5.0).b,
                  rPixel(pos).a);
    }
  """
  RgbSplit* = """
  uniform vec2 offset;

  vec4 rEffect(vec2 pos) {
    return vec4(rPixel(pos - offset).r,
                rPixel(pos).g,
                rPixel(pos + offset).b,
                rPixel(pos).a);
  }
  """
