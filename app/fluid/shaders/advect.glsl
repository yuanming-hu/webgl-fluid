//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform int column;
uniform highp sampler2D uTexture;
uniform highp sampler2D vTexture;
uniform float deltaT;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
vec2 getVel(vec2 pos) {
    vec2 vel;
    vel.x = texture2D(uTexture, vec2((pos.x * bufSize.x + 0.5) / (bufSize.x + 1.), pos.y)).x;
    vel.y = texture2D(vTexture, vec2(pos.x, (pos.y * bufSize.y + 0.5) / (bufSize.y + 1.))).x;
    return vel;
}

void main(void)
{
    vec2 pos;
    if (column == 1) { // u
        pos = (gl_FragCoord.xy - vec2(0.5, 0.0)) / bufSize;
    } else { // v
        pos = (gl_FragCoord.xy - vec2(0.0, 0.5)) / bufSize;
    }
    vec2 midPos = pos - 0.5 * deltaT * getVel(pos);
    vec2 originalPos = pos - deltaT * getVel(midPos);
    vec4 color;
    if (column == 1) {
        color.x = getVel(originalPos).x;
    } else {
        color.x = getVel(originalPos).y;
    }
    color.yzw = vec3(1, 0, 1);
    gl_FragColor = vec4(color);
}
