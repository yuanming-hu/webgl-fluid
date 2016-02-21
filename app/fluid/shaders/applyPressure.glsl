//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform int column;
uniform highp sampler2D vTexture;
uniform highp sampler2D pressureTexture;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
const float r = 10.0;
float decode32(highp vec4 rgba) {
    return (dot(rgba, vec4(1, 1. / 255.0, 1. / 65025.0, 1. / 16581375.0)) - 0.5) * r;
}

void main(void)
{
    vec2 pos = gl_FragCoord.xy / bufSize;
    ivec2 ipos = ivec2(int(gl_FragCoord.x), int(gl_FragCoord.y));
    vec4 color = texture2D(vTexture, pos);
    if (column == 0) { // v
        if (ipos.y == 0 || ipos.y == int(bufSize.y) - 1) {
        } else {
            float p0 = decode32(texture2D(pressureTexture, vec2(pos.x, (float(ipos.y) - 1.) / (bufSize.y - 1.))));
            float p1 = decode32(texture2D(pressureTexture, vec2(pos.x, (float(ipos.y)) / (bufSize.y - 1.))));
            color.x += p0 - p1;
        }
    } else { // u
        if (ipos.x == 0 || ipos.x == int(bufSize.x) - 1) {
        } else {
            float p0 = decode32(texture2D(pressureTexture, vec2((float(ipos.x) - 1.) / (bufSize.x - 1.), pos.y)));
            float p1 = decode32(texture2D(pressureTexture, vec2(float(ipos.x) / (bufSize.x - 1.), pos.y)));
            color.x += p0 - p1;
        }
    }
    gl_FragColor = vec4(color);
}
