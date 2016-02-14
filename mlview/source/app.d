import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
import nanovg;
import mlfe.mapleparser.lexer;
import std.string, std.conv;

void main()
{
	// Load/InitLibrary
	DerelictGL3.load();
	DerelictGLFW3.load();
	if(glfwInit() != GL_TRUE) throw new Exception("GLFW initialization failed.");
	scope(exit) glfwTerminate();
	
	// For Intel Graphics(Forced to use OpenGL 3.3 Core Profile)
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	
	// CreateWindow
	auto pWindow = glfwCreateWindow(640, 480, "mlview", null, null);
	if(pWindow is null) throw new Exception("GLFW Window creation failed.");
	pWindow.glfwMakeContextCurrent();
	// LazyLoading GL3
	DerelictGL3.reload();
	
	// CenteringWindow
	auto vm = glfwGetVideoMode(glfwGetPrimaryMonitor());
	pWindow.glfwSetWindowPos((vm.width - 640) / 2, (vm.height - 480) / 2);
	
	// CreateNanoVGContext/Font
	// (Download and place NotoSans font)
	auto context = new NanoVG.ContextGL3();
	auto fontid = context.createFont("font", "./Ricty-Regular.ttf");
	
	auto tokenList = "{
	var a = new Parser(\"test\");
	return switch(a.front.type)
	{
		case TokenType.String => true;
		default => throw new global.RuntimeError(\"invalid operation\");
	};
}".asTokenList;
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	while(!glfwWindowShouldClose(pWindow))
	{
		int w, h;
		pWindow.glfwGetFramebufferSize(&w, &h);
		glViewport(0, 0, w, h);
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
		with(context)
		{
			beginFrame(w, h, cast(float)w / cast(float)h);
			scope(exit) endFrame();
			
			// Initialize
			fontFace = fontid;
			fontSize = 16.0f;
			fontBlur = 0;
			
			// Title Text
			textAlign = NanoVG.TextAlign.LEFT | NanoVG.TextAlign.TOP;
			foreach(t; tokenList)
			{
				if(t.type == TokenType.EndOfScript) break;
				if(t.hasValue!string)
				{
					if(t.type.isControlKeyword || t.type.isExpressionKeyword || t.type.isTypeKeyword)
					{
						fillColor = nvgRGBAf(0.0f, 0.0f, 1.0f, 1.0f);
					}
					else if(t.type == TokenType.StringLiteral || t.type == TokenType.CharacterLiteral)
					{
						fillColor = nvgRGBAf(0.375f, 0.0f, 0.0f, 1.0f);
					}
					else
					{
						fillColor = nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f);
					}
					string textOutput = t.source;
					if(t.type == TokenType.StringLiteral)
					{
						textOutput = '"' ~ textOutput ~ '"';
					}
					else if(t.type == TokenType.CharacterLiteral)
					{
						textOutput = '\'' ~ textOutput ~ '\'';
					}
					text(8 + (t.at.column - 1) * 7.5, 8 + (t.at.line - 1) * 14, textOutput);
				}
			}
		}
		
		pWindow.glfwSwapBuffers();
		glfwPollEvents();
	}
}
