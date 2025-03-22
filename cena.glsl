#version 330 core

// Definição de texturas
#iChannel0 "file://./Texturas/Grass/Grass004_1K-JPG_Color.jpg"
#iChannel1 "file://./Texturas/Metal/Metal014_1K-JPG_Color.jpg"
#iChannel2 "file://./Texturas/Leather/Leather030.png"

// Uniforms
uniform float     iChannelTime[4];       // Tempo da unidade de canal
// uniform vec2 iResolution;  // Resolução da tela

#define MAX_STEPS 100
#define MAX_DIST 40.
#define SURF_DIST .005

// Definição de materiais
const int mat_support = 1;
const int mat_bar = 2;
const int mat_ball = 3;
const int mat_line = 4;

// Funções para geometria
mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float SDFbox(vec3 pos, vec3 dim) {
    vec3 p = abs(pos) - dim;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float SDFsphere(vec3 pos, float r) {
    return length(pos) - r;
}

float SDF2box(vec2 pos, vec2 dim) {
    vec2 p = abs(pos) - dim;
    return length(max(p, 0.)) + min(max(p.x, p.y), 0.);
}

float SDFseg(vec3 pos, vec3 a, vec3 b) {
    vec3 segDir = b - a;
    float t = max(min(dot(pos - a, segDir)/dot(segDir, segDir), 1.), 0.);
    vec3 q = a + t * (b - a);
    return length(pos - q);
}

vec2 SDFball(vec3 pos, float a) {
    pos.y -= 1.8;
    pos.yx *= Rot(a);
    pos.y += 1.8;
    float sphereDist = SDFsphere(pos - vec3(0, .23, 0), .1);
    vec3 sim = pos;
    sim.z = abs(sim.z);
    float dist = sphereDist;
    return vec2(dist, sphereDist == dist ? mat_ball : mat_line);
}

// Função para desenhar as linhas do campo
float SDFline(vec3 p, vec3 start, vec3 end, float width) {
    float dist = SDFseg(p, start, end);
    return max(dist - width, 0.0);
}

vec2 GetDist(vec3 pos) {
    vec2 ball1 = SDFball(pos, 0.05);
    float support = SDFbox(pos - vec3(0, 0, 0), vec3(1.5, .1, 3.0) - 0.05) - 0.05;
    support = max(support, -pos.y);
    float bar = length(vec2(SDF2box(pos.yx, vec2(1.0, 0.6)), abs(pos.z) - 2.5)) - 0.05;
    bar = max(bar, -pos.y);
    vec2 ball = ball1;
    float dist = min(min(support, bar), ball.x);
    int mat = 0;
    if (dist == support) mat = mat_support;
    else if (dist == bar) mat = mat_bar;
    else if (dist == ball.x) mat = int(ball.y);
    return vec2(dist, mat);
}

vec2 RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;
    vec2 dS = vec2(0.);
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = ro + rd * dO;
        dS = GetDist(pos);
        dO += dS.x;
        if(dO > MAX_DIST || dS.x < SURF_DIST) break;
    }
    return vec2(dO, dS.y);
}

vec3 GetNormal(vec3 pos) {
    float dist = GetDist(pos).x;
    vec2 eps = vec2(.01, 0);
    vec3 norm = dist - vec3(
        GetDist(pos - eps.xyy).x,
        GetDist(pos - eps.yxy).x,
        GetDist(pos - eps.yyx).x);
    return normalize(norm);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
         r = normalize(cross(vec3(0, 1, 0), f)),
         u = cross(f, r),
         c = f * z,
         i = c + uv.x * r + uv.y * u,
         d = normalize(i);
    return d;
}

vec3 getSunPosition(float time) {
    float angle = time * 0.1;
    float height = sin(angle) * 5.0;
    float x = cos(angle) * 20.0;
    float z = sin(angle) * 20.0;
    return vec3(x, height, 1.0);
}

vec3 getSunColor(vec3 sunPos) {
    float sunHeight = normalize(sunPos).y;
    return mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.9, 0.7), smoothstep(0.0, 0.5, sunHeight));
}

vec3 getSunAtmosphere(vec3 rd, vec3 sunDir) {
    float sunDot = max(dot(rd, sunDir), 0.0);
    float sunIntensity = pow(sunDot, 256.0) * 2.0;
    float sunGlow = pow(sunDot, 8.0) * 0.2;
    vec3 sunColor = getSunColor(sunDir);
    return sunColor * (sunIntensity + sunGlow);
}

// Função para pegar as coordenadas de textura do suporte
vec2 getTextureCoordinates(vec3 p) {
    // Mapeamento de coordenadas de textura para o suporte (ajustado conforme o tamanho do objeto)
    return p.xz * 0.5 + 0.5;  // Ajuste a escala e a posição conforme necessário
}

float calcShadow(vec3 ro, vec3 rd, float mint, float maxt) {
    float res = 1.0;
    float t = mint;
    for(int i = 0; i < 16; i++) {
        float h = GetDist(ro + rd * t).x;
        if(h < 0.001) return 0.0;
        res = min(res, 8.0 * h / t);
        t += h;
        if(t > maxt) break;
    }
    return res;
}

vec3 Render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last) {
    vec3 sunPos = getSunPosition(iTime);
    vec3 sunDir = normalize(sunPos);
    vec3 sunColor = getSunColor(sunPos);

    vec3 col = vec3(0.000, 0.000, 0.000); // Cor do céu
    col += getSunAtmosphere(rd, sunDir);

    vec2 d = RayMarch(ro, rd);

    if (d.x < MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);

        float sunDif = max(dot(n, sunDir), 0.0);
        float skyLight = 0.5 + 0.5 * n.y;
        float bounceLight = max(0.0, -n.y) * 0.3;
        float shadow = calcShadow(p + n * 0.01, sunDir, 0.1, 10.0);
        float lighting = sunDif * shadow * 1.5 + skyLight * 0.5 + bounceLight;

        vec2 uv = fract(p.xz * 0.5 + 0.5); // Mapeamento de coordenadas de textura
        
        // Grama
        if (d.y == float(mat_support)) {
            col = texture(iChannel0, uv).rgb;  // Aplica a textura de grama
            col *= lighting;  // Aplica a iluminação
        }
        // Outros materiais (trave, bola, etc)
        else if (d.y == float(mat_bar)) {
            col = texture(iChannel1, uv).rgb;  // Textura da trave
        } else if (d.y == float(mat_ball)) {
            col = texture(iChannel2, uv).rgb;  // Textura da bola
        }

        // Reflexão suavizada
        float reflectionStrength = 0.1;
        vec3 reflectedColor = texture(iChannel0, uv).rgb;  // Reflexo (ex: mármore)
        float normalDot = max(dot(n, sunDir), 0.0);  // Intensidade de luz
        vec3 blurredReflection = mix(reflectedColor, col, 0.7);  // Suaviza o reflexo
        col = mix(col, blurredReflection, reflectionStrength * normalDot);

        // Reflexo com Fresnel
        float fresnel = pow(1.0 - dot(n, rd), 3.0) * 0.9 + 0.1;  // Efeito Fresnel
        col = mix(col, reflectedColor, fresnel * reflectionStrength);

        col *= lighting;
        ro = p + 3. * n * SURF_DIST;
        rd = r;
    } else {
        ref = vec3(0.0);
    }

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = vec4(1, 0, 0, 1);
    
    // Corrige a resolução
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Inicializa a posição da câmera e o vetor de direção
    vec3 ro = vec3(0, 3, -7);

    ro.yz *= Rot(-iMouse.y * 3.14 + 1.0);
    ro.xz = ro.xz * Rot(-iMouse.x * 6.2831);

    vec3 rd = GetRayDir(uv, ro, vec3(0, 0.75, 0), 1.6);
    vec3 ref = vec3(1.);

    // Chama a função Render
    vec3 col = Render(ro, rd, ref, false);

    // Número de reflexões
    int NB_BOUNCE = 2;

    // // Reflexão adicional
    // for (int i = 0; i < NB_BOUNCE; i++) {
    //     vec3 ref1 = ref;
    //     col += ref1 * Render(ro, rd, ref, i + 1 == NB_BOUNCE);
    // }

    // Aplica uma transformação de cor
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0); // Atribui a cor final ao fragmento
}