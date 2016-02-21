//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform highp sampler2D vTexture;
uniform int backup;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 pos = gl_FragCoord.xy / bufSize;
    ivec2 ipos = ivec2(int(gl_FragCoord.x), int(gl_FragCoord.y));
    vec4 color = texture2D(vTexture, pos);
    if (color.y > 0.0)
        color = vec4(color.x / color.y, 0, 0, 1);
    else
        color = vec4(0, 0, 0, 1);
    if (backup == 1)
        color.y = color.x;
    gl_FragColor = vec4(color);
}
