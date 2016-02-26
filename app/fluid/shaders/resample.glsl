//***     Globals     ***
attribute vec2 position;
uniform highp sampler2D particleTexture;
uniform highp sampler2D uTexture;
uniform highp sampler2D vTexture;
uniform float flipAlpha;
uniform vec2 bufSize;
uniform int rk2;
varying vec2 textureCoord;
uniform float deltaT;

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

vec2 getBackupVel(vec2 pos) {
    vec2 vel;
    vel.x = texture2D(uTexture, vec2((pos.x * bufSize.x + 0.5) / (bufSize.x + 1.), pos.y)).y;
    vel.y = texture2D(vTexture, vec2(pos.x, (pos.y * bufSize.y + 0.5) / (bufSize.y + 1.))).y;
    return vel;
}

vec2 sampleFlipVelocity(in vec2 pos, in vec2 particleVel) {
    vec2 vel = getVel(pos);
    vec2 backupVel = getBackupVel(pos);
    return (1. - flipAlpha) * (vel) + flipAlpha * (particleVel + vel - backupVel);
}

void main(void)
{
    vec4 data = texture2D(particleTexture, textureCoord);
    data.zw = sampleFlipVelocity(data.xy, data.zw);
    if (rk2 == 1) {
        data.zw = sampleFlipVelocity(data.xy + data.zw * deltaT, data.zw);
    }
    gl_FragColor = data;
}

