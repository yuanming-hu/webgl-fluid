//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform highp sampler2D systemTexture;
uniform highp sampler2D pressure;
uniform highp float damping;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
const float r = 10.0;
vec4 encode32(float v) {
    v = clamp(v / r, -0.5, 0.5) + 0.5;
    vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
    enc = fract(enc);
    enc -= enc.yzww * vec4(1. / 255.0, 1. / 255.0, 1. / 255.0, 0);
    return enc;
}

float decode32(highp vec4 rgba) {
    return (dot(rgba, vec4(1., 1. / 255.0, 1. / 65025.0, 1. / 16581375.0)) - 0.5) * r;
}

void main(void)
{
    vec2 pos = gl_FragCoord.xy / bufSize;
    vec4 sys = texture2D(systemTexture, pos);
    vec2 dx = vec2(1, 0) / bufSize, dy = vec2(0, 1) / bufSize;
    float Ax = sys.x, Ay = sys.y, Ad = sys.z, rhs = sys.w;
    float p = rhs;
    if (Ad == -1.0) {
        p = 0.0;
    } else {
        float px, nx, py, ny, last;
        px = decode32(texture2D(pressure, pos + dx));
        nx = decode32(texture2D(pressure, pos - dx));
        py = decode32(texture2D(pressure, pos + dy));
        ny = decode32(texture2D(pressure, pos - dy));
        last = decode32(texture2D(pressure, pos));
        if (mod(Ax, 2.0) == 1.0) {
            p += px;
        }
        if (floor(Ax * 0.5) == 1.0) {
            p += nx;
        }
        if (mod(Ay, 2.0) == 1.0) {
            p += py;
        }
        if (floor(Ay * 0.5) == 1.0) {
            p += ny;
        }
        p *= Ad;
        p = (1. - damping) * last + damping * p;
    }
    gl_FragColor = encode32(p);
}
