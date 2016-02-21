//***     Globals     ***
attribute vec2 position;
uniform highp sampler2D particleTexture;
uniform float deltaT;
uniform vec2 bufSize;
uniform vec2 gravity;
varying vec2 textureCoord;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
    textureCoord = position * 0.5 + vec2(0.5);
}

//*** Fragment Shader ***

void main(void)
{
    vec4 data = texture2D(particleTexture, textureCoord);
    gl_FragColor = vec4(data.xy, data.zw + gravity * deltaT);
}

