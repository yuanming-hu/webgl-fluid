//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform vec2 offset;
uniform int scene;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 pos;
    pos = 0.5 * gl_FragCoord.xy / bufSize;
    if (scene == 0) {
        pos += offset;
    } else if (scene == 1) {
        if (pos.x < 0.25) {
            pos.x += 0.55;
        } else {
            pos.x -= 0.2;
        }
        pos.x += 0.1;
    } else if (scene == 2 || scene == 3) {
        if (pos.y > 0.25) {
            pos += vec2(0.5, -0.25);
        }
        if (scene == 2) {
            pos.y += 0.5;
        }
    }
    gl_FragColor = vec4(pos, 0, 0);
}
