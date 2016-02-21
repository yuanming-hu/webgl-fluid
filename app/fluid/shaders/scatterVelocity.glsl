//***     Globals     ***
attribute float id;
uniform highp sampler2D texture;
uniform vec2 bufSize;
uniform int isU;
varying vec4 data;

//***  Vertex Shader  ***
void main(void)
{
    float hid = id + 0.5;
    float width = bufSize.x;
    float x = floor(mod(hid, width));
    float y = floor(hid / width);
    data = texture2D(texture, vec2(x, y) / bufSize);
    vec2 pos = data.xy;
    if (isU == 1) {
        pos = (pos * bufSize + vec2(0.5, 0)) / vec2(bufSize.x + 1.0, bufSize.y);
    } else {
        pos = (pos * bufSize + vec2(0, 0.5)) / vec2(bufSize.x, bufSize.y + 1.0);
    }
    pos = pos * 2. - vec2(1);
    gl_Position = vec4(pos, 0.0, 1.0);
    gl_PointSize = 2.;
}

//*** Fragment Shader ***
void main(void)
{
    vec2 dist = 1. - abs(gl_PointCoord * 2. - 1.);
    float N = dist.x * dist.y;
    float u;
    if (isU == 1) {
        u = data.z;
    } else {
        u = data.w;
    }
    gl_FragColor = vec4(u * N, N, 0, 1);
}