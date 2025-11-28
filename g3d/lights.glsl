// diffuse lighting shader

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

uniform float distTime;
uniform float shake;

uniform float ambientBase;
uniform float ambientBrightness;
uniform vec3 ambientDirection;
uniform vec3 ambientColor;

uniform vec3[10] pointLightPosition;
uniform vec2[10] pointLightData; // {brightness, range}
uniform vec3[10] pointLightColor;

uniform mat4[10] spotLightPosition;
uniform vec3[10] spotLightData; // {brightness, range, angle}
uniform vec3[10] spotLightColor;

varying vec3 normal;
varying vec3 vertexP;

#ifdef VERTEX
	attribute vec4 VertexNormal;

	// A simple pseudo-random number generator
	float random1(vec4 st) {
		return fract(sin(dot(st.xyzw, vec4(12.9898, 78.233, 35.123, distTime))) * 43758.5453123) * 2 - 1;
	}
	float random2(vec4 st) {
		return fract(sin(dot(st.xyzw, vec4(distTime, 12.9898, 78.233, 35.123))) * 43758.5453123) * 2 - 1;
	}
	float random3(vec4 st) {
		return fract(sin(dot(st.xyzw, vec4(35.123, distTime, 12.9898, 78.233))) * 43758.5453123) * 2 - 1;
	}

	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		// Direction of the surface normal vector in world space
		normal = normalize(mat3(modelMatrix) * vec3(VertexNormal));

		float r1 = random1(vertex_position);
		float r2 = random2(vertex_position);
		float r3 = random3(vertex_position);
		
		vertex_position += (shake * vec4(r1, r2, r3, 0));

		// Position of the vertex in world space
		vertexP = vec3(modelMatrix * vec4(vertex_position));

		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL

	// Get how much of the surface is facing the light source (1 is direct sunlight, 0 is perpendicular or behind)
	float flux(vec3 vector)
	{
		return max(dot(normalize(vector), normal), 0.0);
	}

	// Get the angle in degrees between two vectors
	float angle(vec3 v1, vec3 v2)
	{
		return degrees(acos(clamp(dot(normalize(v1), normalize(v2)), -1.0, 1.0)));
	}

	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(tex, texcoord);

		// Ignore if this vertex is not visible
		if (texcolor.a == 0.0 || color.a == 0.0) { discard; }		

		// Apply vertex colors and ambient color
		texcolor *= color * vec4(ambientColor, 1);

		// Apply diffuse ambient lighting (surfaces facing the light source are brighter)
		texcolor.rgb *= (flux(ambientDirection) * ambientBrightness + ambientBase);

		// Apply lighting from other sources (max 10 of each type)
		vec3 direction;
		for (int i = 0; i < 10; i++)
		{
			// Point lights (shine in a sphere like a light bulb)
			direction = pointLightPosition[i] - vertexP;
			texcolor.rgb += pointLightColor[i]							// color
				* flux(direction)										// diffusion
				* pointLightData[i].x									// brightness
				* max(0, 1 - length(direction) / pointLightData[i].y);	// distance (1 at the source, 0 if outside the radius)

			// Spot lights (shine in one direction like a flashlight)
			direction = vertexP - vec3(spotLightPosition[i][3]);
			texcolor.rgb += spotLightColor[i]																// color
				* flux(-direction)																			// diffusion
				* spotLightData[i].x																		// brightness
				* max(0, 1 - length(direction) / spotLightData[i].y)										// distance (1 at the source, 0 past the end of the beam)
				* max(0, 1 - angle(-vec3(spotLightPosition[i][0]), direction) / (spotLightData[i].z / 2));	// angle (1 if parallel along beam, 0 if outside of the cone)
		}

		return texcolor;
	}
#endif