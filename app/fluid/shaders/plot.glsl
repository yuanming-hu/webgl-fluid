//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform vec2 screenSize;
uniform vec2 offset;
uniform highp sampler2D texture;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 textureCoord = ((gl_FragCoord.xy / screenSize) * (bufSize + offset) - 0.5 * offset) / bufSize;
    vec4 tex = texture2D(texture, textureCoord);
    gl_FragColor = vec4(tex);
}