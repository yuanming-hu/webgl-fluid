//***     Globals     ***
attribute vec2 position;
uniform highp sampler2D particleTexture;
uniform highp sampler2D uTexture;
uniform highp sampler2D vTexture;
uniform float deltaT;
uniform vec2 bufSize;
varying vec2 textureCoord;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
    textureCoord = position * 0.5 + vec2(0.5);
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
    vec4 data = texture2D(particleTexture, textureCoord);
    vec2 vel = data.zw;
    vec2 newPos = data.xy + deltaT * vel;
    gl_FragColor = vec4(newPos, vel);
}

