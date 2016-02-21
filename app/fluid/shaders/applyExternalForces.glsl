//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform float deltaT;
uniform float acc;
uniform highp sampler2D vTexture;
uniform int dragging;
uniform vec2 mouseCoord;
uniform float strength;
uniform int isU;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 coord = gl_FragCoord.xy / bufSize;
    vec4 color = texture2D(vTexture, coord);
    float totalAcc = acc;
    if (dragging == 1) {
        vec2 pos;
        if (isU == 1) {
            pos = (gl_FragCoord.xy - vec2(0.5, 0)) / vec2(bufSize.x - 1.0, bufSize.y);
        } else {
            pos = (gl_FragCoord.xy - vec2(0, 0.5)) / vec2(bufSize.x, bufSize.y - 1.0);
        }
        vec2 dist = (pos - mouseCoord);
        vec2 force = strength * dist / pow(length(dist) + 0.1, 3.);
        if (isU == 1) {
            totalAcc += force.x;
        } else {
            totalAcc += force.y;
        }
    }
    color.x += deltaT * totalAcc;
    gl_FragColor = color;
}
