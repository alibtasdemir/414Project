#version 440

in vec4 vCol;
in vec2 TexCoord;
in vec3 Normal;
in vec3 FragPos;

out vec4 color;

struct Light
{
	vec3 color;
	float ambientIntensity;
	float diffuseIntensity;
};

struct DirectionalLight
{
	Light base;
	vec3 direction;
};

struct PointLight
{
	Light base;
	vec3 position;
	float constant;
	float linear_;
	float exponent;
};

struct SpotLight
{
	PointLight base;
	vec3 direction;
	float edge;
};

struct Material
{
	float specularIntensity;
	float shininess;
};


uniform DirectionalLight directionalLight;
uniform SpotLight spotLight;

uniform sampler2D theTexture;
uniform Material material;

uniform vec3 eyePosition;

vec4 CalcLightByDirection(Light light, vec3 direction)
{
	vec4 ambientColor = vec4(light.color, 1.0f) * light.ambientIntensity;

	float diffuseFactor = max(dot(normalize(Normal), normalize(direction)), 0.0f);
	vec4 diffuseColor = vec4(light.color * light.diffuseIntensity * diffuseFactor, 1.0f);

	vec4 specularColor = vec4(0, 0, 0, 0);

	if (diffuseFactor > 0.0f)
	{
		vec3 fragToEye = normalize(eyePosition - FragPos);
		vec3 reflectedVertex = normalize(reflect(direction, normalize(Normal)));

		float specularFactor = dot(fragToEye, reflectedVertex);
		if (specularFactor > 0.0f)
		{
			specularFactor = pow(specularFactor, material.shininess);
			specularColor = vec4(light.color * material.specularIntensity * specularFactor, 1.0f);
		}
	}

	return (ambientColor + diffuseColor + specularColor);
}

vec4 CalcPointLight(PointLight pLight)
{
	vec3 direction = FragPos - pLight.position;
	float distance = length(direction);
	direction = normalize(direction);

	vec4 color = CalcLightByDirection(pLight.base, direction);
	float attenuation = pLight.exponent * distance * distance +
		pLight.linear_ * distance +
		pLight.constant;

	return (color / attenuation);
}

vec4 CalcSpotLight(SpotLight sLight)
{
	vec3 rayDirection = normalize(FragPos - sLight.base.position);
	float slFactor = dot(rayDirection, sLight.direction);

	if (slFactor > sLight.edge)
	{
		vec4 color = CalcPointLight(sLight.base);

		return color * (1.0f - (1.0f - slFactor)*(1.0f / (1.0f - sLight.edge)));

	}
	else {
		return vec4(0, 0, 0, 0);
	}
}

float remap( float minval, float maxval, float curval )
{
    return ( curval - minval ) / ( maxval - minval );
} 
//                       r      b    g
const vec4 deepWater = vec4( 0.0, 0.0, 1.0, 1.0 );
const vec4 water = vec4( 0.1, 0.1, 1.0, 1.0 );
const vec4 sand = vec4( 0.8, 0.8, 0.0, 1.0 );
const vec4 grass = vec4( 0.1, 0.9, 0.1, 1.0 );
const vec4 rock = vec4( 0.4, 0.3, 0.2, 1.0 );
const vec4 snow = vec4( 1.0, 1.0, 1.0, 1.0 );

void main()
{
	vec4 finalColor = CalcLightByDirection(directionalLight.base, directionalLight.direction);
	//finalColor += CalcPointLights();
	finalColor += CalcSpotLight(spotLight);

	//color = texture(theTexture, TexCoord) * finalColor;
	vec4 terrainColor;
	float terrainYSize = 10;//10.4;
	float u = (FragPos.y);
	
	if( u > 0.8 * terrainYSize )
	terrainColor = snow;
	else if(u > 0.4 * terrainYSize)
	terrainColor = rock;
	else if (u > 0.3 * terrainYSize)
	terrainColor = grass;
	else if (u > 0.2 * terrainYSize)
	terrainColor = sand;
	else if (u > 0.1 * terrainYSize)
	terrainColor = water;
	else
	terrainColor = deepWater;

	color = terrainColor * finalColor;

}