#version 330 core

#iChannel0 "file://Texturas/Grass/Grass004.png"
#iChannel1 "file://Texturas/Metal/Metal014.png"
#iChannel2 "file://vecteezy_football-soccer-field-vector-illustration-coach-table-for_6797269_112/soccerfield.jpg"
#iChannel3 "file://vecteezy_football-soccer-field-vector-illustration-coach-table-for_6797269_112/soccerfield.jpg"

// uniform float     iTimeDelta;            // render time (in seconds)
// uniform float     iFrameRate;            // shader frame rate
// uniform int       iFrame;                // shader playback frame
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

#define MAX_STEPS 100
#define MAX_DIST 50.
#define SURF_DIST .005


// Definição de materiais
const int mat_support = 1;
const int mat_bar = 2;
const int mat_ball = 3;
const int mat_line = 4;

// Funções para geometria
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float SDFbox(vec3 pos, vec3 dim) {
    vec3 p = abs(pos) - dim;;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);;
}

float SDFsphere(vec3 pos, float r) {
    return length(pos) - r;
}

float SDF2box(vec2 pos, vec2 dim) {
    vec2 p = abs(pos) - dim;
    return length(max(p, 0.)) + min(max(p.x, p.y), 0.);;
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
	vec4 sphere = vec4(0, 1, 6, 1);
    
    float a = 0.78 * cos(iTime * 1.5) * min(10. / iTime, 1.);
    float aplus = min(a, 0.);
    float amin = max(a, 0.);
    
    vec2 ball1 = SDFball(pos, 0.05 * a);
    
    float support = SDFbox(pos - vec3(0, 0, 0), vec3(1.5, .1, 3.0)-0.05) - 0.05;
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
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

/// Add this before your mainImage function
vec3 getSunPosition(float time) {
    // Control the angle of the sun's horizontal movement around the scene
    float angle = time * 0.1; // The sun moves around the scene slowly
    // Control the height of the sun, creating a day-night cycle
    float height = cos(angle) * 0.5 + 0.5; // The sun goes from 0 to 1 (below horizon to above)
    // You can add an offset to control the time of day for testing
    float x = cos(angle) * 20.0; // Horizontal movement
    float z = sin(angle) * 20.0; // Horizontal movement

    // The sun's position in 3D space
    return vec3(x, height * 20.0, z); 
}

// Calculate sun color based on height (more orange/red when low)
vec3 getSunColor(vec3 sunPos) {
    float sunHeight = normalize(sunPos).y;
    return mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.9, 0.7), smoothstep(0.0, 0.5, sunHeight));
}

// Add sun atmosphere when looking towards the sun
vec3 getSunAtmosphere(vec3 rd, vec3 sunDir) {
    float sunDot = max(dot(rd, sunDir), 0.0);
    float sunIntensity = pow(sunDot, 256.0) * 2.0; // Sun core
    float sunGlow = pow(sunDot, 8.0) * 0.2; // Sun glow
    
    vec3 sunColor = getSunColor(sunDir);
    return sunColor * (sunIntensity + sunGlow);
}

// Add shadow ray function
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
   // Posição do sol baseada no tempo
   vec3 sunPos = getSunPosition(iTime);
   vec3 sunDir = normalize(sunPos);
   vec3 sunColor = getSunColor(sunPos);

   // Cor do céu e fundo com o sol
   vec3 col = vec3(0.000, 0.000, 0.000); // Cor do céu
   col += getSunAtmosphere(rd, sunDir); // Glória do sol (efeito de brilho)

   vec2 d = RayMarch(ro, rd);

   if (d.x < MAX_DIST) {
      vec3 p = ro + rd * d.x;
      vec3 n = GetNormal(p);  // Normal no ponto de interseção
      vec3 r = reflect(rd, n);  // Reflexão da direção do raio

      // Iluminação dinâmica com base na posição do sol
      float sunDif = max(dot(n, sunDir), 0.0); // Luz direta do sol
      float skyLight = 0.5 + 0.5 * n.y; // Luz ambiental do céu
      float bounceLight = max(0.0, -n.y) * 0.3; // Luz refletida no chão

      // Iluminação combinada com sombras
      float shadow = calcShadow(p + n * 0.01, sunDir, 0.1, 10.0); // Cálculo de sombra
      float lighting = sunDif * shadow * 1.5 + skyLight * 0.5 + bounceLight; // Luz final

      // Mapeamento de UV com base na posição no mundo para diferentes objetos
      // Adiciona a amostragem da textura
    vec2 uv = fract(p.xz * 0.5); // Mapeamento UV para o campo

    if (int(d.y) == mat_support) {
        // Padrão de tabuleiro para suporte com textura de grama
        // Utiliza a textura de grama (iChannel0) no campo
        vec4 grassColor = texture(iChannel0, uv); // Amostra a textura de grama
        col = grassColor.rgb; // Aplica a cor da textura ao campo
        ref *= vec3(mix(0.01, 0.3, uv.x)); // Reflexão para o campo
    } 
      else if (int(d.y) == mat_bar) {
          // Padrão de listras para a barra
          uv.x = fract(p.y * 2.0);
          float stripe = smoothstep(0.45, 0.55, uv.x);
          col = mix(vec3(0.7), vec3(0.3), stripe);
          ref *= vec3(0.9);
      } 
      else if (int(d.y) == mat_ball) {
          // Mapeamento esférico para a bola
          vec3 localPos = p - vec3(0, 0.23, 0);
          float phi = atan(localPos.z, localPos.x);
          float theta = acos(localPos.y / 0.1);
          uv = vec2(phi / (2.0 * 3.14159) + 0.5, theta / 3.14159);

          // Criar uma textura simples para a bola (exemplo de mármore)
          float marble = sin(uv.x * 20.0 + sin(uv.y * 10.0) * 0.5) * 0.5 + 0.5;
          col = mix(vec3(0.8, 0.6, 0.2), vec3(1.0, 0.9, 0.5), marble);
          ref *= vec3(0.9, 0.65, 0.2) * (marble * 0.5 + 0.5);
      }

      // Aplicar iluminação para o objeto
      col *= lighting; // Modifica a cor com base na iluminação calculada

      ro = p + 3. * n * SURF_DIST; // Atualiza a posição do observador
      rd = r; // Atualiza a direção do raio
   } else {
      ref = vec3(0.0); // Se não houver interseção, a cor é preta
   }

   return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Corrige a resolução
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Definir m com base na posição do mouse
    vec2 m = iMouse.xy / iResolution.xy;  // Normaliza a posição do mouse para o intervalo [0, 1]
    
    // Inicializa a posição da câmera e o vetor de direção
    vec3 ro = vec3(0, 3, -7);
    
    // Aplicar a rotação correta no vetor ro.xz
    ro.yz *= Rot(-m.y * 3.14 + 1.);  // Rotação no plano yz
    ro.xz = ro.xz * Rot(-m.x * 6.2831);  // Rotação no plano xz
    
    vec3 rd = GetRayDir(uv, ro, vec3(0, 0.75, 0), 1.6);
    
    vec3 ref = vec3(1.);

    // Chama a função Render para calcular a cor da cena
    vec3 col = Render(ro, rd, ref, false);
    
    // Número de reflexões
    int NB_BOUNCE = 2;
    
    // Reflexão adicional
    for (int i = 0; i < NB_BOUNCE; i++) {
        vec3 ref1 = ref; // Reflete o valor atual da cor
        col += ref1 * Render(ro, rd, ref, i + 1 == NB_BOUNCE);
    }
    
    // Aplica uma transformação de cor para o resultado final
    col = pow(col, vec3(0.4545));

    // Atribui a cor final ao fragmento
    fragColor = vec4(col, 1.0);
}