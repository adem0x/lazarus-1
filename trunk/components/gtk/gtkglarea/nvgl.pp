// File: NVGL.pp        
// modified: 11-03-2002
//
// FreePascal Bindings for libGL by NVIDIA (based on MESA Bindings from Sebastian G�nther)
// Version 0.0.4
// supported NVIDIA Driver Version: 2880
// Copyright (C) 2001 Satan


{$MODE objfpc}

unit NVGL;

{$linklib GL}

interface

// =======================================================
//   Unit specific extensions
// =======================================================


var
  GLDumpUnresolvedFunctions,
  GLInitialized: Boolean;


// =======================================================
//   GL consts, types and functions
// =======================================================


// -------------------------------------------------------
//   GL types
// -------------------------------------------------------

type
  PSingle   = ^Single;
  PDouble   = ^Double;
  PShortInt = ^ShortInt;
  PLongword = ^Longword;

  GLvoid    = Pointer;
  GLboolean = Byte;

  GLbyte    = ShortInt; // 1-byte signed
  GLshort   = Integer;  // 2-byte signed
  GLint     = LongInt;  // 4-byte signed

  GLubyte   = Byte;     // 1-byte unsigned
  GLushort  = Word;     // 2-byte unsigned
  GLuint    = DWord;    // 4-byte signed

  GLsizei   = LongInt;  // 4-byte signed

  GLfloat   = Single;   // single precision float
  GLclampf  = Single;   // single precision float in [0,1]
  GLdouble  = Double;   // double precision float
  GLclampd  = Double;   // double precision float in [0,1]

  GLenum    = DWord;

  PGLBoolean = ^GLBoolean;
  PGLFloat   = ^GLfloat;
  PGLDouble  = ^GLDouble;

// -------------------------------------------------------
  PGLubyte = ^GLubyte;
  PGLuint = ^GLuint;
  PGLvoid = ^GLvoid;
  PGLint = ^GLint;
  PGLshort = ^GLshort;
  PGLbyte = ^GLbyte;
  PGLushort = ^GLushort;
  PGLSizei = ^GLSizei;
// -------------------------------------------------------

type
  GLbitfield = DWord;  { was an enum - no corresponding thing in pascal }

// -------------------------------------------------------
//   const
// -------------------------------------------------------

  const
     GL_VERSION_1_1 = 1;
     GL_VERSION_1_2 = 1;
     GL_VERSION_1_3 = 1;
  { Extensions  }
     GL_ARB_imaging = 1;
     GL_ARB_multisample = 1;
     GL_ARB_multitexture = 1;
     GL_ARB_texture_border_clamp = 1;
     GL_ARB_texture_compression = 1;
     GL_ARB_texture_cube_map = 1;
     GL_ARB_texture_env_add = 1;
     GL_ARB_texture_env_combine = 1;
     GL_ARB_texture_env_dot3 = 1;
     GL_ARB_transpose_matrix = 1;
     GL_Autodesk_valid_back_buffer_hint = 1;
     GL_EXT_abgr = 1;
     GL_EXT_bgra = 1;
     GL_EXT_blend_color = 1;
     GL_EXT_blend_minmax = 1;
     GL_EXT_blend_subtract = 1;
     GL_EXT_clip_volume_hint = 1;
     GL_EXT_compiled_vertex_array = 1;
     GL_EXT_color_table = 1;
     GL_EXT_draw_range_elements = 1;
     GL_EXT_fog_coord = 1;
     GL_EXT_multi_draw_arrays = 1;
     GL_EXT_packed_pixels = 1;
     GL_EXT_paletted_texture = 1;
     GL_EXT_point_parameters = 1;
     GL_EXT_rescale_normal = 1;
     GL_EXT_secondary_color = 1;
     GL_EXT_separate_specular_color = 1;
     GL_EXT_shared_texture_palette = 1;
     GL_EXT_stencil_wrap = 1;
     GL_EXT_texture3D = 1;
     GL_EXT_texture_compression_s3tc = 1;
     GL_EXT_texture_cube_map = 1;
     GL_EXT_texture_edge_clamp = 1;
     GL_EXT_texture_env_add = 1;
     GL_EXT_texture_env_combine = 1;
     GL_EXT_texture_env_dot3 = 1;
     GL_EXT_texture_filter_anisotropic = 1;
     GL_EXT_texture_lod_bias = 1;
     GL_EXT_texture_object = 1;
     GL_EXT_vertex_array = 1;
     GL_EXT_vertex_weighting = 1;
     GL_HP_occlusion_test = 1;
     GL_IBM_texture_mirrored_repeat = 1;
     GL_NV_blend_square = 1;
     GL_NV_copy_depth_to_color = 1;
     GL_NV_depth_clamp = 1;
     GL_NV_draw_mesh = 1;
     GL_NV_evaluators = 1;
     GL_NV_fence = 1;
     GL_NV_flusHold = 1;
     GL_NV_fog_distance = 1;
     GL_NV_light_max_exponent = 1;
     GL_NV_mac_get_proc_address = 1;
     GL_NV_multisample_filter_hint = 1;
     GL_NV_occlusion_query = 1;
     GL_NV_packed_depth_stencil = 1;
     GL_NV_point_sprite = 1;
     GL_NV_register_combiners = 1;
     GL_NV_register_combiners2 = 1;
     GL_NV_set_window_stereomode = 1;
     GL_NV_texgen_emboss = 1;
     GL_NV_texgen_reflection = 1;
     GL_NV_texture_compression_vtc = 1;
     GL_NV_texture_env_combine4 = 1;
     GL_NV_texture_rectangle = 1;
     GL_NV_texture_shader = 1;
     GL_NV_texture_shader2 = 1;
     GL_NV_texture_shader3 = 1;
     GL_NV_vertex_array_range = 1;
     GL_NV_vertex_array_range2 = 1;
     GL_NV_vertex_program = 1;
     GL_NV_vertex_program1_1 = 1;
     GL_S3_s3tc = 1;
     GL_SGIS_generate_mipmap = 1;
     GL_SGIS_multitexture = 1;
     GL_SGIS_texture_lod = 1;
     GL_SGIX_depth_texture = 1;
     GL_SGIX_shadow = 1;
     GL_APPLE_transform_hint = 1;
     GL_WIN_swap_hint = 1;
  { AttribMask  }
     GL_CURRENT_BIT = $00000001;
     GL_POINT_BIT = $00000002;
     GL_LINE_BIT = $00000004;
     GL_POLYGON_BIT = $00000008;
     GL_POLYGON_STIPPLE_BIT = $00000010;
     GL_PIXEL_MODE_BIT = $00000020;
     GL_LIGHTING_BIT = $00000040;
     GL_FOG_BIT = $00000080;
     GL_DEPTH_BUFFER_BIT = $00000100;
     GL_ACCUM_BUFFER_BIT = $00000200;
     GL_STENCIL_BUFFER_BIT = $00000400;
     GL_VIEWPORT_BIT = $00000800;
     GL_TRANSFORM_BIT = $00001000;
     GL_ENABLE_BIT = $00002000;
     GL_COLOR_BUFFER_BIT = $00004000;
     GL_HINT_BIT = $00008000;
     GL_EVAL_BIT = $00010000;
     GL_LIST_BIT = $00020000;
     GL_TEXTURE_BIT = $00040000;
     GL_SCISSOR_BIT = $00080000;
     GL_ALL_ATTRIB_BITS = $FFFFFFFF;
  { ClearBufferMask  }
  {      GL_COLOR_BUFFER_BIT  }
  {      GL_ACCUM_BUFFER_BIT  }
  {      GL_STENCIL_BUFFER_BIT  }
  {      GL_DEPTH_BUFFER_BIT  }
  { ClientAttribMask  }
     GL_CLIENT_PIXEL_STORE_BIT = $00000001;
     GL_CLIENT_VERTEX_ARRAY_BIT = $00000002;
     GL_CLIENT_ALL_ATTRIB_BITS = $FFFFFFFF;
  { Boolean  }
     GL_FALSE = 0;
     GL_TRUE = 1;
  { BeginMode  }
     GL_POINTS = $0000;
     GL_LINES = $0001;
     GL_LINE_LOOP = $0002;
     GL_LINE_STRIP = $0003;
     GL_TRIANGLES = $0004;
     GL_TRIANGLE_STRIP = $0005;
     GL_TRIANGLE_FAN = $0006;
     GL_QUADS = $0007;
     GL_QUAD_STRIP = $0008;
     GL_POLYGON = $0009;
  { AccumOp  }
     GL_ACCUM = $0100;
     GL_LOAD = $0101;
     GL_RETURN = $0102;
     GL_MULT = $0103;
     GL_ADD = $0104;
  { AlphaFunction  }
     GL_NEVER = $0200;
     GL_LESS = $0201;
     GL_EQUAL = $0202;
     GL_LEQUAL = $0203;
     GL_GREATER = $0204;
     GL_NOTEQUAL = $0205;
     GL_GEQUAL = $0206;
     GL_ALWAYS = $0207;
  { BlendingFactorDest  }
     GL_ZERO = 0;
     GL_ONE = 1;
     GL_SRC_COLOR = $0300;
     GL_ONE_MINUS_SRC_COLOR = $0301;
     GL_SRC_ALPHA = $0302;
     GL_ONE_MINUS_SRC_ALPHA = $0303;
     GL_DST_ALPHA = $0304;
     GL_ONE_MINUS_DST_ALPHA = $0305;
  { BlendingFactorSrc  }
  {      GL_ZERO  }
  {      GL_ONE  }
     GL_DST_COLOR = $0306;
     GL_ONE_MINUS_DST_COLOR = $0307;
     GL_SRC_ALPHA_SATURATE = $0308;
  {      GL_SRC_ALPHA  }
  {      GL_ONE_MINUS_SRC_ALPHA  }
  {      GL_DST_ALPHA  }
  {      GL_ONE_MINUS_DST_ALPHA  }
  { ColorMaterialFace  }
  {      GL_FRONT  }
  {      GL_BACK  }
  {      GL_FRONT_AND_BACK  }
  { ColorMaterialParameter  }
  {      GL_AMBIENT  }
  {      GL_DIFFUSE  }
  {      GL_SPECULAR  }
  {      GL_EMISSION  }
  {      GL_AMBIENT_AND_DIFFUSE  }
  { ColorPointerType  }
  {      GL_BYTE  }
  {      GL_UNSIGNED_BYTE  }
  {      GL_SHORT  }
  {      GL_UNSIGNED_SHORT  }
  {      GL_INT  }
  {      GL_UNSIGNED_INT  }
  {      GL_FLOAT  }
  {      GL_DOUBLE  }
  { CullFaceMode  }
  {      GL_FRONT  }
  {      GL_BACK  }
  {      GL_FRONT_AND_BACK  }
  { DepthFunction  }
  {      GL_NEVER  }
  {      GL_LESS  }
  {      GL_EQUAL  }
  {      GL_LEQUAL  }
  {      GL_GREATER  }
  {      GL_NOTEQUAL  }
  {      GL_GEQUAL  }
  {      GL_ALWAYS  }
  { DrawBufferMode  }
     GL_NONE = 0;
     GL_FRONT_LEFT = $0400;
     GL_FRONT_RIGHT = $0401;
     GL_BACK_LEFT = $0402;
     GL_BACK_RIGHT = $0403;
     GL_FRONT = $0404;
     GL_BACK = $0405;
     GL_LEFT = $0406;
     GL_RIGHT = $0407;
     GL_FRONT_AND_BACK = $0408;
     GL_AUX0 = $0409;
     GL_AUX1 = $040A;
     GL_AUX2 = $040B;
     GL_AUX3 = $040C;
  { EnableCap  }
  {      GL_FOG  }
  {      GL_LIGHTING  }
  {      GL_TEXTURE_1D  }
  {      GL_TEXTURE_2D  }
  {      GL_LINE_STIPPLE  }
  {      GL_POLYGON_STIPPLE  }
  {      GL_CULL_FACE  }
  {      GL_ALPHA_TEST  }
  {      GL_BLEND  }
  {      GL_INDEX_LOGIC_OP  }
  {      GL_COLOR_LOGIC_OP  }
  {      GL_DITHER  }
  {      GL_STENCIL_TEST  }
  {      GL_DEPTH_TEST  }
  {      GL_CLIP_PLANE0  }
  {      GL_CLIP_PLANE1  }
  {      GL_CLIP_PLANE2  }
  {      GL_CLIP_PLANE3  }
  {      GL_CLIP_PLANE4  }
  {      GL_CLIP_PLANE5  }
  {      GL_LIGHT0  }
  {      GL_LIGHT1  }
  {      GL_LIGHT2  }
  {      GL_LIGHT3  }
  {      GL_LIGHT4  }
  {      GL_LIGHT5  }
  {      GL_LIGHT6  }
  {      GL_LIGHT7  }
  {      GL_TEXTURE_GEN_S  }
  {      GL_TEXTURE_GEN_T  }
  {      GL_TEXTURE_GEN_R  }
  {      GL_TEXTURE_GEN_Q  }
  {      GL_MAP1_VERTEX_3  }
  {      GL_MAP1_VERTEX_4  }
  {      GL_MAP1_COLOR_4  }
  {      GL_MAP1_INDEX  }
  {      GL_MAP1_NORMAL  }
  {      GL_MAP1_TEXTURE_COORD_1  }
  {      GL_MAP1_TEXTURE_COORD_2  }
  {      GL_MAP1_TEXTURE_COORD_3  }
  {      GL_MAP1_TEXTURE_COORD_4  }
  {      GL_MAP2_VERTEX_3  }
  {      GL_MAP2_VERTEX_4  }
  {      GL_MAP2_COLOR_4  }
  {      GL_MAP2_INDEX  }
  {      GL_MAP2_NORMAL  }
  {      GL_MAP2_TEXTURE_COORD_1  }
  {      GL_MAP2_TEXTURE_COORD_2  }
  {      GL_MAP2_TEXTURE_COORD_3  }
  {      GL_MAP2_TEXTURE_COORD_4  }
  {      GL_POINT_SMOOTH  }
  {      GL_LINE_SMOOTH  }
  {      GL_POLYGON_SMOOTH  }
  {      GL_SCISSOR_TEST  }
  {      GL_COLOR_MATERIAL  }
  {      GL_NORMALIZE  }
  {      GL_AUTO_NORMAL  }
  {      GL_POLYGON_OFFSET_POINT  }
  {      GL_POLYGON_OFFSET_LINE  }
  {      GL_POLYGON_OFFSET_FILL  }
  {      GL_VERTEX_ARRAY  }
  {      GL_NORMAL_ARRAY  }
  {      GL_COLOR_ARRAY  }
  {      GL_INDEX_ARRAY  }
  {      GL_TEXTURE_COORD_ARRAY  }
  {      GL_EDGE_FLAG_ARRAY  }
  { ErrorCode  }
     GL_NO_ERROR = 0;
     GL_INVALID_ENUM = $0500;
     GL_INVALID_VALUE = $0501;
     GL_INVALID_OPERATION = $0502;
     GL_STACK_OVERFLOW = $0503;
     GL_STACK_UNDERFLOW = $0504;
     GL_OUT_OF_MEMORY = $0505;
     GL_TABLE_TOO_LARGE = $8031;
  { FeedbackType  }
     GL_2D = $0600;
     GL_3D = $0601;
     GL_3D_COLOR = $0602;
     GL_3D_COLOR_TEXTURE = $0603;
     GL_4D_COLOR_TEXTURE = $0604;
  { FeedBackToken  }
     GL_PASS_THROUGH_TOKEN = $0700;
     GL_POINT_TOKEN = $0701;
     GL_LINE_TOKEN = $0702;
     GL_POLYGON_TOKEN = $0703;
     GL_BITMAP_TOKEN = $0704;
     GL_DRAW_PIXEL_TOKEN = $0705;
     GL_COPY_PIXEL_TOKEN = $0706;
     GL_LINE_RESET_TOKEN = $0707;
  { FogMode  }
  {      GL_LINEAR  }
     GL_EXP = $0800;
     GL_EXP2 = $0801;
  { FogParameter  }
  {      GL_FOG_COLOR  }
  {      GL_FOG_DENSITY  }
  {      GL_FOG_END  }
  {      GL_FOG_INDEX  }
  {      GL_FOG_MODE  }
  {      GL_FOG_START  }
  { FrontFaceDirection  }
     GL_CW = $0900;
     GL_CCW = $0901;
  { GetColorTableParameterPNameEXT  }
  {      GL_COLOR_TABLE_FORMAT_EXT  }
  {      GL_COLOR_TABLE_WIDTH_EXT  }
  {      GL_COLOR_TABLE_RED_SIZE_EXT  }
  {      GL_COLOR_TABLE_GREEN_SIZE_EXT  }
  {      GL_COLOR_TABLE_BLUE_SIZE_EXT  }
  {      GL_COLOR_TABLE_ALPHA_SIZE_EXT  }
  {      GL_COLOR_TABLE_LUMINANCE_SIZE_EXT  }
  {      GL_COLOR_TABLE_INTENSITY_SIZE_EXT  }
  { GetMapQuery  }
     GL_COEFF = $0A00;
     GL_ORDER = $0A01;
     GL_DOMAIN = $0A02;
  { GetPixelMap  }
     GL_PIXEL_MAP_I_TO_I = $0C70;
     GL_PIXEL_MAP_S_TO_S = $0C71;
     GL_PIXEL_MAP_I_TO_R = $0C72;
     GL_PIXEL_MAP_I_TO_G = $0C73;
     GL_PIXEL_MAP_I_TO_B = $0C74;
     GL_PIXEL_MAP_I_TO_A = $0C75;
     GL_PIXEL_MAP_R_TO_R = $0C76;
     GL_PIXEL_MAP_G_TO_G = $0C77;
     GL_PIXEL_MAP_B_TO_B = $0C78;
     GL_PIXEL_MAP_A_TO_A = $0C79;
  { GetPointervPName  }
     GL_VERTEX_ARRAY_POINTER = $808E;
     GL_NORMAL_ARRAY_POINTER = $808F;
     GL_COLOR_ARRAY_POINTER = $8090;
     GL_INDEX_ARRAY_POINTER = $8091;
     GL_TEXTURE_COORD_ARRAY_POINTER = $8092;
     GL_EDGE_FLAG_ARRAY_POINTER = $8093;
  { GetPName  }
     GL_CURRENT_COLOR = $0B00;
     GL_CURRENT_INDEX = $0B01;
     GL_CURRENT_NORMAL = $0B02;
     GL_CURRENT_TEXTURE_COORDS = $0B03;
     GL_CURRENT_RASTER_COLOR = $0B04;
     GL_CURRENT_RASTER_INDEX = $0B05;
     GL_CURRENT_RASTER_TEXTURE_COORDS = $0B06;
     GL_CURRENT_RASTER_POSITION = $0B07;
     GL_CURRENT_RASTER_POSITION_VALID = $0B08;
     GL_CURRENT_RASTER_DISTANCE = $0B09;
     GL_POINT_SMOOTH = $0B10;
     GL_POINT_SIZE = $0B11;
     GL_SMOOTH_POINT_SIZE_RANGE = $0B12;
     GL_SMOOTH_POINT_SIZE_GRANULARITY = $0B13;
     GL_POINT_SIZE_RANGE = GL_SMOOTH_POINT_SIZE_RANGE;
     GL_POINT_SIZE_GRANULARITY = GL_SMOOTH_POINT_SIZE_GRANULARITY;
     GL_LINE_SMOOTH = $0B20;
     GL_LINE_WIDTH = $0B21;
     GL_SMOOTH_LINE_WIDTH_RANGE = $0B22;
     GL_SMOOTH_LINE_WIDTH_GRANULARITY = $0B23;
     GL_LINE_WIDTH_RANGE = GL_SMOOTH_LINE_WIDTH_RANGE;
     GL_LINE_WIDTH_GRANULARITY = GL_SMOOTH_LINE_WIDTH_GRANULARITY;
     GL_LINE_STIPPLE = $0B24;
     GL_LINE_STIPPLE_PATTERN = $0B25;
     GL_LINE_STIPPLE_REPEAT = $0B26;
     GL_LIST_MODE = $0B30;
     GL_MAX_LIST_NESTING = $0B31;
     GL_LIST_BASE = $0B32;
     GL_LIST_INDEX = $0B33;
     GL_POLYGON_MODE = $0B40;
     GL_POLYGON_SMOOTH = $0B41;
     GL_POLYGON_STIPPLE = $0B42;
     GL_EDGE_FLAG = $0B43;
     GL_CULL_FACE = $0B44;
     GL_CULL_FACE_MODE = $0B45;
     GL_FRONT_FACE = $0B46;
     GL_LIGHTING = $0B50;
     GL_LIGHT_MODEL_LOCAL_VIEWER = $0B51;
     GL_LIGHT_MODEL_TWO_SIDE = $0B52;
     GL_LIGHT_MODEL_AMBIENT = $0B53;
     GL_SHADE_MODEL = $0B54;
     GL_COLOR_MATERIAL_FACE = $0B55;
     GL_COLOR_MATERIAL_PARAMETER = $0B56;
     GL_COLOR_MATERIAL = $0B57;
     GL_FOG = $0B60;
     GL_FOG_INDEX = $0B61;
     GL_FOG_DENSITY = $0B62;
     GL_FOG_START = $0B63;
     GL_FOG_END = $0B64;
     GL_FOG_MODE = $0B65;
     GL_FOG_COLOR = $0B66;
     GL_DEPTH_RANGE = $0B70;
     GL_DEPTH_TEST = $0B71;
     GL_DEPTH_WRITEMASK = $0B72;
     GL_DEPTH_CLEAR_VALUE = $0B73;
     GL_DEPTH_FUNC = $0B74;
     GL_ACCUM_CLEAR_VALUE = $0B80;
     GL_STENCIL_TEST = $0B90;
     GL_STENCIL_CLEAR_VALUE = $0B91;
     GL_STENCIL_FUNC = $0B92;
     GL_STENCIL_VALUE_MASK = $0B93;
     GL_STENCIL_FAIL = $0B94;
     GL_STENCIL_PASS_DEPTH_FAIL = $0B95;
     GL_STENCIL_PASS_DEPTH_PASS = $0B96;
     GL_STENCIL_REF = $0B97;
     GL_STENCIL_WRITEMASK = $0B98;
     GL_MATRIX_MODE = $0BA0;
     GL_NORMALIZE = $0BA1;
     GL_VIEWPORT = $0BA2;
     GL_MODELVIEW_STACK_DEPTH = $0BA3;
     GL_PROJECTION_STACK_DEPTH = $0BA4;
     GL_TEXTURE_STACK_DEPTH = $0BA5;
     GL_MODELVIEW_MATRIX = $0BA6;
     GL_PROJECTION_MATRIX = $0BA7;
     GL_TEXTURE_MATRIX = $0BA8;
     GL_ATTRIB_STACK_DEPTH = $0BB0;
     GL_CLIENT_ATTRIB_STACK_DEPTH = $0BB1;
     GL_ALPHA_TEST = $0BC0;
     GL_ALPHA_TEST_FUNC = $0BC1;
     GL_ALPHA_TEST_REF = $0BC2;
     GL_DITHER = $0BD0;
     GL_BLEND_DST = $0BE0;
     GL_BLEND_SRC = $0BE1;
     GL_BLEND = $0BE2;
     GL_LOGIC_OP_MODE = $0BF0;
     GL_INDEX_LOGIC_OP = $0BF1;
     GL_LOGIC_OP = GL_INDEX_LOGIC_OP;
     GL_COLOR_LOGIC_OP = $0BF2;
     GL_AUX_BUFFERS = $0C00;
     GL_DRAW_BUFFER = $0C01;
     GL_READ_BUFFER = $0C02;
     GL_SCISSOR_BOX = $0C10;
     GL_SCISSOR_TEST = $0C11;
     GL_INDEX_CLEAR_VALUE = $0C20;
     GL_INDEX_WRITEMASK = $0C21;
     GL_COLOR_CLEAR_VALUE = $0C22;
     GL_COLOR_WRITEMASK = $0C23;
     GL_INDEX_MODE = $0C30;
     GL_RGBA_MODE = $0C31;
     GL_DOUBLEBUFFER = $0C32;
     GL_STEREO = $0C33;
     GL_RENDER_MODE = $0C40;
     GL_PERSPECTIVE_CORRECTION_HINT = $0C50;
     GL_POINT_SMOOTH_HINT = $0C51;
     GL_LINE_SMOOTH_HINT = $0C52;
     GL_POLYGON_SMOOTH_HINT = $0C53;
     GL_FOG_HINT = $0C54;
     GL_TEXTURE_GEN_S = $0C60;
     GL_TEXTURE_GEN_T = $0C61;
     GL_TEXTURE_GEN_R = $0C62;
     GL_TEXTURE_GEN_Q = $0C63;
     GL_PIXEL_MAP_I_TO_I_SIZE = $0CB0;
     GL_PIXEL_MAP_S_TO_S_SIZE = $0CB1;
     GL_PIXEL_MAP_I_TO_R_SIZE = $0CB2;
     GL_PIXEL_MAP_I_TO_G_SIZE = $0CB3;
     GL_PIXEL_MAP_I_TO_B_SIZE = $0CB4;
     GL_PIXEL_MAP_I_TO_A_SIZE = $0CB5;
     GL_PIXEL_MAP_R_TO_R_SIZE = $0CB6;
     GL_PIXEL_MAP_G_TO_G_SIZE = $0CB7;
     GL_PIXEL_MAP_B_TO_B_SIZE = $0CB8;
     GL_PIXEL_MAP_A_TO_A_SIZE = $0CB9;
     GL_UNPACK_SWAP_BYTES = $0CF0;
     GL_UNPACK_LSB_FIRST = $0CF1;
     GL_UNPACK_ROW_LENGTH = $0CF2;
     GL_UNPACK_SKIP_ROWS = $0CF3;
     GL_UNPACK_SKIP_PIXELS = $0CF4;
     GL_UNPACK_ALIGNMENT = $0CF5;
     GL_PACK_SWAP_BYTES = $0D00;
     GL_PACK_LSB_FIRST = $0D01;
     GL_PACK_ROW_LENGTH = $0D02;
     GL_PACK_SKIP_ROWS = $0D03;
     GL_PACK_SKIP_PIXELS = $0D04;
     GL_PACK_ALIGNMENT = $0D05;
     GL_MAP_COLOR = $0D10;
     GL_MAP_STENCIL = $0D11;
     GL_INDEX_SHIFT = $0D12;
     GL_INDEX_OFFSET = $0D13;
     GL_RED_SCALE = $0D14;
     GL_RED_BIAS = $0D15;
     GL_ZOOM_X = $0D16;
     GL_ZOOM_Y = $0D17;
     GL_GREEN_SCALE = $0D18;
     GL_GREEN_BIAS = $0D19;
     GL_BLUE_SCALE = $0D1A;
     GL_BLUE_BIAS = $0D1B;
     GL_ALPHA_SCALE = $0D1C;
     GL_ALPHA_BIAS = $0D1D;
     GL_DEPTH_SCALE = $0D1E;
     GL_DEPTH_BIAS = $0D1F;
     GL_MAX_EVAL_ORDER = $0D30;
     GL_MAX_LIGHTS = $0D31;
     GL_MAX_CLIP_PLANES = $0D32;
     GL_MAX_TEXTURE_SIZE = $0D33;
     GL_MAX_PIXEL_MAP_TABLE = $0D34;
     GL_MAX_ATTRIB_STACK_DEPTH = $0D35;
     GL_MAX_MODELVIEW_STACK_DEPTH = $0D36;
     GL_MAX_NAME_STACK_DEPTH = $0D37;
     GL_MAX_PROJECTION_STACK_DEPTH = $0D38;
     GL_MAX_TEXTURE_STACK_DEPTH = $0D39;
     GL_MAX_VIEWPORT_DIMS = $0D3A;
     GL_MAX_CLIENT_ATTRIB_STACK_DEPTH = $0D3B;
     GL_SUBPIXEL_BITS = $0D50;
     GL_INDEX_BITS = $0D51;
     GL_RED_BITS = $0D52;
     GL_GREEN_BITS = $0D53;
     GL_BLUE_BITS = $0D54;
     GL_ALPHA_BITS = $0D55;
     GL_DEPTH_BITS = $0D56;
     GL_STENCIL_BITS = $0D57;
     GL_ACCUM_RED_BITS = $0D58;
     GL_ACCUM_GREEN_BITS = $0D59;
     GL_ACCUM_BLUE_BITS = $0D5A;
     GL_ACCUM_ALPHA_BITS = $0D5B;
     GL_NAME_STACK_DEPTH = $0D70;
     GL_AUTO_NORMAL = $0D80;
     GL_MAP1_COLOR_4 = $0D90;
     GL_MAP1_INDEX = $0D91;
     GL_MAP1_NORMAL = $0D92;
     GL_MAP1_TEXTURE_COORD_1 = $0D93;
     GL_MAP1_TEXTURE_COORD_2 = $0D94;
     GL_MAP1_TEXTURE_COORD_3 = $0D95;
     GL_MAP1_TEXTURE_COORD_4 = $0D96;
     GL_MAP1_VERTEX_3 = $0D97;
     GL_MAP1_VERTEX_4 = $0D98;
     GL_MAP2_COLOR_4 = $0DB0;
     GL_MAP2_INDEX = $0DB1;
     GL_MAP2_NORMAL = $0DB2;
     GL_MAP2_TEXTURE_COORD_1 = $0DB3;
     GL_MAP2_TEXTURE_COORD_2 = $0DB4;
     GL_MAP2_TEXTURE_COORD_3 = $0DB5;
     GL_MAP2_TEXTURE_COORD_4 = $0DB6;
     GL_MAP2_VERTEX_3 = $0DB7;
     GL_MAP2_VERTEX_4 = $0DB8;
     GL_MAP1_GRID_DOMAIN = $0DD0;
     GL_MAP1_GRID_SEGMENTS = $0DD1;
     GL_MAP2_GRID_DOMAIN = $0DD2;
     GL_MAP2_GRID_SEGMENTS = $0DD3;
     GL_TEXTURE_1D = $0DE0;
     GL_TEXTURE_2D = $0DE1;
     GL_FEEDBACK_BUFFER_POINTER = $0DF0;
     GL_FEEDBACK_BUFFER_SIZE = $0DF1;
     GL_FEEDBACK_BUFFER_TYPE = $0DF2;
     GL_SELECTION_BUFFER_POINTER = $0DF3;
     GL_SELECTION_BUFFER_SIZE = $0DF4;
     GL_POLYGON_OFFSET_UNITS = $2A00;
     GL_POLYGON_OFFSET_POINT = $2A01;
     GL_POLYGON_OFFSET_LINE = $2A02;
     GL_POLYGON_OFFSET_FILL = $8037;
     GL_POLYGON_OFFSET_FACTOR = $8038;
     GL_TEXTURE_BINDING_1D = $8068;
     GL_TEXTURE_BINDING_2D = $8069;
     GL_TEXTURE_BINDING_3D = $806A;
     GL_VERTEX_ARRAY = $8074;
     GL_NORMAL_ARRAY = $8075;
     GL_COLOR_ARRAY = $8076;
     GL_INDEX_ARRAY = $8077;
     GL_TEXTURE_COORD_ARRAY = $8078;
     GL_EDGE_FLAG_ARRAY = $8079;
     GL_VERTEX_ARRAY_SIZE = $807A;
     GL_VERTEX_ARRAY_TYPE = $807B;
     GL_VERTEX_ARRAY_STRIDE = $807C;
     GL_NORMAL_ARRAY_TYPE = $807E;
     GL_NORMAL_ARRAY_STRIDE = $807F;
     GL_COLOR_ARRAY_SIZE = $8081;
     GL_COLOR_ARRAY_TYPE = $8082;
     GL_COLOR_ARRAY_STRIDE = $8083;
     GL_INDEX_ARRAY_TYPE = $8085;
     GL_INDEX_ARRAY_STRIDE = $8086;
     GL_TEXTURE_COORD_ARRAY_SIZE = $8088;
     GL_TEXTURE_COORD_ARRAY_TYPE = $8089;
     GL_TEXTURE_COORD_ARRAY_STRIDE = $808A;
     GL_EDGE_FLAG_ARRAY_STRIDE = $808C;
  {      GL_VERTEX_ARRAY_COUNT_EXT  }
  {      GL_NORMAL_ARRAY_COUNT_EXT  }
  {      GL_COLOR_ARRAY_COUNT_EXT  }
  {      GL_INDEX_ARRAY_COUNT_EXT  }
  {      GL_TEXTURE_COORD_ARRAY_COUNT_EXT  }
  {      GL_EDGE_FLAG_ARRAY_COUNT_EXT  }
  {      GL_ARRAY_ELEMENT_LOCK_COUNT_EXT  }
  {      GL_ARRAY_ELEMENT_LOCK_FIRST_EXT  }
  { GetTextureParameter  }
  {      GL_TEXTURE_MAG_FILTER  }
  {      GL_TEXTURE_MIN_FILTER  }
  {      GL_TEXTURE_WRAP_S  }
  {      GL_TEXTURE_WRAP_T  }
     GL_TEXTURE_WIDTH = $1000;
     GL_TEXTURE_HEIGHT = $1001;
     GL_TEXTURE_INTERNAL_FORMAT = $1003;
     GL_TEXTURE_COMPONENTS = GL_TEXTURE_INTERNAL_FORMAT;
     GL_TEXTURE_BORDER_COLOR = $1004;
     GL_TEXTURE_BORDER = $1005;
     GL_TEXTURE_RED_SIZE = $805C;
     GL_TEXTURE_GREEN_SIZE = $805D;
     GL_TEXTURE_BLUE_SIZE = $805E;
     GL_TEXTURE_ALPHA_SIZE = $805F;
     GL_TEXTURE_LUMINANCE_SIZE = $8060;
     GL_TEXTURE_INTENSITY_SIZE = $8061;
     GL_TEXTURE_PRIORITY = $8066;
     GL_TEXTURE_RESIDENT = $8067;
  { HintMode  }
     GL_DONT_CARE = $1100;
     GL_FASTEST = $1101;
     GL_NICEST = $1102;
  { HintTarget  }
  {      GL_PERSPECTIVE_CORRECTION_HINT  }
  {      GL_POINT_SMOOTH_HINT  }
  {      GL_LINE_SMOOTH_HINT  }
  {      GL_POLYGON_SMOOTH_HINT  }
  {      GL_FOG_HINT  }
  { IndexMaterialParameterSGI  }
  {      GL_INDEX_OFFSET  }
  { IndexPointerType  }
  {      GL_SHORT  }
  {      GL_INT  }
  {      GL_FLOAT  }
  {      GL_DOUBLE  }
  { IndexFunctionSGI  }
  {      GL_NEVER  }
  {      GL_LESS  }
  {      GL_EQUAL  }
  {      GL_LEQUAL  }
  {      GL_GREATER  }
  {      GL_NOTEQUAL  }
  {      GL_GEQUAL  }
  {      GL_ALWAYS  }
  { LightModelParameter  }
  {      GL_LIGHT_MODEL_AMBIENT  }
  {      GL_LIGHT_MODEL_LOCAL_VIEWER  }
  {      GL_LIGHT_MODEL_TWO_SIDE  }
  { LightParameter  }
     GL_AMBIENT = $1200;
     GL_DIFFUSE = $1201;
     GL_SPECULAR = $1202;
     GL_POSITION = $1203;
     GL_SPOT_DIRECTION = $1204;
     GL_SPOT_EXPONENT = $1205;
     GL_SPOT_CUTOFF = $1206;
     GL_CONSTANT_ATTENUATION = $1207;
     GL_LINEAR_ATTENUATION = $1208;
     GL_QUADRATIC_ATTENUATION = $1209;
  { ListMode  }
     GL_COMPILE = $1300;
     GL_COMPILE_AND_EXECUTE = $1301;
  { DataType  }
     GL_BYTE = $1400;
     GL_UNSIGNED_BYTE = $1401;
     GL_SHORT = $1402;
     GL_UNSIGNED_SHORT = $1403;
     GL_INT = $1404;
     GL_UNSIGNED_INT = $1405;
     GL_FLOAT = $1406;
     GL_2_BYTES = $1407;
     GL_3_BYTES = $1408;
     GL_4_BYTES = $1409;
     GL_DOUBLE = $140A;
     GL_DOUBLE_EXT = $140A;
  { ListNameType  }
  {      GL_BYTE  }
  {      GL_UNSIGNED_BYTE  }
  {      GL_SHORT  }
  {      GL_UNSIGNED_SHORT  }
  {      GL_INT  }
  {      GL_UNSIGNED_INT  }
  {      GL_FLOAT  }
  {      GL_2_BYTES  }
  {      GL_3_BYTES  }
  {      GL_4_BYTES  }
  { LogicOp  }
     GL_CLEAR = $1500;
     GL_AND = $1501;
     GL_AND_REVERSE = $1502;
     GL_COPY = $1503;
     GL_AND_INVERTED = $1504;
     GL_NOOP = $1505;
     GL_XOR = $1506;
     GL_OR = $1507;
     GL_NOR = $1508;
     GL_EQUIV = $1509;
     GL_INVERT = $150A;
     GL_OR_REVERSE = $150B;
     GL_COPY_INVERTED = $150C;
     GL_OR_INVERTED = $150D;
     GL_NAND = $150E;
     GL_SET = $150F;
  { MapTarget  }
  {      GL_MAP1_COLOR_4  }
  {      GL_MAP1_INDEX  }
  {      GL_MAP1_NORMAL  }
  {      GL_MAP1_TEXTURE_COORD_1  }
  {      GL_MAP1_TEXTURE_COORD_2  }
  {      GL_MAP1_TEXTURE_COORD_3  }
  {      GL_MAP1_TEXTURE_COORD_4  }
  {      GL_MAP1_VERTEX_3  }
  {      GL_MAP1_VERTEX_4  }
  {      GL_MAP2_COLOR_4  }
  {      GL_MAP2_INDEX  }
  {      GL_MAP2_NORMAL  }
  {      GL_MAP2_TEXTURE_COORD_1  }
  {      GL_MAP2_TEXTURE_COORD_2  }
  {      GL_MAP2_TEXTURE_COORD_3  }
  {      GL_MAP2_TEXTURE_COORD_4  }
  {      GL_MAP2_VERTEX_3  }
  {      GL_MAP2_VERTEX_4  }
  { MaterialFace  }
  {      GL_FRONT  }
  {      GL_BACK  }
  {      GL_FRONT_AND_BACK  }
  { MaterialParameter  }
     GL_EMISSION = $1600;
     GL_SHININESS = $1601;
     GL_AMBIENT_AND_DIFFUSE = $1602;
     GL_COLOR_INDEXES = $1603;
  {      GL_AMBIENT  }
  {      GL_DIFFUSE  }
  {      GL_SPECULAR  }
  { MatrixMode  }
     GL_MODELVIEW = $1700;
     GL_PROJECTION = $1701;
     GL_TEXTURE = $1702;
  { MeshMode1  }
  {      GL_POINT  }
  {      GL_LINE  }
  { MeshMode2  }
  {      GL_POINT  }
  {      GL_LINE  }
  {      GL_FILL  }
  { NormalPointerType  }
  {      GL_BYTE  }
  {      GL_SHORT  }
  {      GL_INT  }
  {      GL_FLOAT  }
  {      GL_DOUBLE  }
  { PixelCopyType  }
     GL_COLOR = $1800;
     GL_DEPTH = $1801;
     GL_STENCIL = $1802;
  { PixelFormat  }
     GL_COLOR_INDEX = $1900;
     GL_STENCIL_INDEX = $1901;
     GL_DEPTH_COMPONENT = $1902;
     GL_RED = $1903;
     GL_GREEN = $1904;
     GL_BLUE = $1905;
     GL_ALPHA = $1906;
     GL_RGB = $1907;
     GL_RGBA = $1908;
     GL_LUMINANCE = $1909;
     GL_LUMINANCE_ALPHA = $190A;
  {      GL_ABGR_EXT  }
  {      GL_BGR_EXT  }
  {      GL_BGRA_EXT  }
  { PixelMap  }
  {      GL_PIXEL_MAP_I_TO_I  }
  {      GL_PIXEL_MAP_S_TO_S  }
  {      GL_PIXEL_MAP_I_TO_R  }
  {      GL_PIXEL_MAP_I_TO_G  }
  {      GL_PIXEL_MAP_I_TO_B  }
  {      GL_PIXEL_MAP_I_TO_A  }
  {      GL_PIXEL_MAP_R_TO_R  }
  {      GL_PIXEL_MAP_G_TO_G  }
  {      GL_PIXEL_MAP_B_TO_B  }
  {      GL_PIXEL_MAP_A_TO_A  }
  { PixelStoreParameter  }
  {      GL_UNPACK_SWAP_BYTES  }
  {      GL_UNPACK_LSB_FIRST  }
  {      GL_UNPACK_ROW_LENGTH  }
  {      GL_UNPACK_SKIP_ROWS  }
  {      GL_UNPACK_SKIP_PIXELS  }
  {      GL_UNPACK_ALIGNMENT  }
  {      GL_PACK_SWAP_BYTES  }
  {      GL_PACK_LSB_FIRST  }
  {      GL_PACK_ROW_LENGTH  }
  {      GL_PACK_SKIP_ROWS  }
  {      GL_PACK_SKIP_PIXELS  }
  {      GL_PACK_ALIGNMENT  }
  { PixelTransferParameter  }
  {      GL_MAP_COLOR  }
  {      GL_MAP_STENCIL  }
  {      GL_INDEX_SHIFT  }
  {      GL_INDEX_OFFSET  }
  {      GL_RED_SCALE  }
  {      GL_RED_BIAS  }
  {      GL_GREEN_SCALE  }
  {      GL_GREEN_BIAS  }
  {      GL_BLUE_SCALE  }
  {      GL_BLUE_BIAS  }
  {      GL_ALPHA_SCALE  }
  {      GL_ALPHA_BIAS  }
  {      GL_DEPTH_SCALE  }
  {      GL_DEPTH_BIAS  }
  { PixelType  }
     GL_BITMAP = $1A00;
  {      GL_BYTE  }
  {      GL_UNSIGNED_BYTE  }
  {      GL_SHORT  }
  {      GL_UNSIGNED_SHORT  }
  {      GL_INT  }
  {      GL_UNSIGNED_INT  }
  {      GL_FLOAT  }
  {      GL_UNSIGNED_BYTE_3_3_2_EXT  }
  {      GL_UNSIGNED_SHORT_4_4_4_4_EXT  }
  {      GL_UNSIGNED_SHORT_5_5_5_1_EXT  }
  {      GL_UNSIGNED_INT_8_8_8_8_EXT  }
  {      GL_UNSIGNED_INT_10_10_10_2_EXT  }
  { PolygonMode  }
     GL_POINT = $1B00;
     GL_LINE = $1B01;
     GL_FILL = $1B02;
  { ReadBufferMode  }
  {      GL_FRONT_LEFT  }
  {      GL_FRONT_RIGHT  }
  {      GL_BACK_LEFT  }
  {      GL_BACK_RIGHT  }
  {      GL_FRONT  }
  {      GL_BACK  }
  {      GL_LEFT  }
  {      GL_RIGHT  }
  {      GL_AUX0  }
  {      GL_AUX1  }
  {      GL_AUX2  }
  {      GL_AUX3  }
  { RenderingMode  }
     GL_RENDER = $1C00;
     GL_FEEDBACK = $1C01;
     GL_SELECT = $1C02;
  { ShadingModel  }
     GL_FLAT = $1D00;
     GL_SMOOTH = $1D01;
  { StencilFunction  }
  {      GL_NEVER  }
  {      GL_LESS  }
  {      GL_EQUAL  }
  {      GL_LEQUAL  }
  {      GL_GREATER  }
  {      GL_NOTEQUAL  }
  {      GL_GEQUAL  }
  {      GL_ALWAYS  }
  { StencilOp  }
  {      GL_ZERO  }
     GL_KEEP = $1E00;
     GL_REPLACE = $1E01;
     GL_INCR = $1E02;
     GL_DECR = $1E03;
  {      GL_INVERT  }
  { StringName  }
     GL_VENDOR = $1F00;
     GL_RENDERER = $1F01;
     GL_VERSION = $1F02;
     GL_EXTENSIONS = $1F03;
  { TexCoordPointerType  }
  {      GL_SHORT  }
  {      GL_INT  }
  {      GL_FLOAT  }
  {      GL_DOUBLE  }
  { TextureCoordName  }
     GL_S = $2000;
     GL_T = $2001;
     GL_R = $2002;
     GL_Q = $2003;
  { TextureEnvMode  }
     GL_MODULATE = $2100;
     GL_DECAL = $2101;
  {      GL_BLEND  }
  {      GL_REPLACE  }
  {      GL_ADD  }
  { TextureEnvParameter  }
     GL_TEXTURE_ENV_MODE = $2200;
     GL_TEXTURE_ENV_COLOR = $2201;
  { TextureEnvTarget  }
     GL_TEXTURE_ENV = $2300;
  { TextureGenMode  }
     GL_EYE_LINEAR = $2400;
     GL_OBJECT_LINEAR = $2401;
     GL_SPHERE_MAP = $2402;
  { TextureGenParameter  }
     GL_TEXTURE_GEN_MODE = $2500;
     GL_OBJECT_PLANE = $2501;
     GL_EYE_PLANE = $2502;
  { TextureMagFilter  }
     GL_NEAREST = $2600;
     GL_LINEAR = $2601;
  { TextureMinFilter  }
  {      GL_NEAREST  }
  {      GL_LINEAR  }
     GL_NEAREST_MIPMAP_NEAREST = $2700;
     GL_LINEAR_MIPMAP_NEAREST = $2701;
     GL_NEAREST_MIPMAP_LINEAR = $2702;
     GL_LINEAR_MIPMAP_LINEAR = $2703;
  { TextureParameterName  }
     GL_TEXTURE_MAG_FILTER = $2800;
     GL_TEXTURE_MIN_FILTER = $2801;
     GL_TEXTURE_WRAP_S = $2802;
     GL_TEXTURE_WRAP_T = $2803;
  {      GL_TEXTURE_BORDER_COLOR  }
  {      GL_TEXTURE_PRIORITY  }
  { TextureTarget  }
  {      GL_TEXTURE_1D  }
  {      GL_TEXTURE_2D  }
     GL_PROXY_TEXTURE_1D = $8063;
     GL_PROXY_TEXTURE_2D = $8064;
  { TextureWrapMode  }
     GL_CLAMP = $2900;
     GL_REPEAT = $2901;
  { PixelInternalFormat  }
     GL_R3_G3_B2 = $2A10;
     GL_ALPHA4 = $803B;
     GL_ALPHA8 = $803C;
     GL_ALPHA12 = $803D;
     GL_ALPHA16 = $803E;
     GL_LUMINANCE4 = $803F;
     GL_LUMINANCE8 = $8040;
     GL_LUMINANCE12 = $8041;
     GL_LUMINANCE16 = $8042;
     GL_LUMINANCE4_ALPHA4 = $8043;
     GL_LUMINANCE6_ALPHA2 = $8044;
     GL_LUMINANCE8_ALPHA8 = $8045;
     GL_LUMINANCE12_ALPHA4 = $8046;
     GL_LUMINANCE12_ALPHA12 = $8047;
     GL_LUMINANCE16_ALPHA16 = $8048;
     GL_INTENSITY = $8049;
     GL_INTENSITY4 = $804A;
     GL_INTENSITY8 = $804B;
     GL_INTENSITY12 = $804C;
     GL_INTENSITY16 = $804D;
     GL_RGB4 = $804F;
     GL_RGB5 = $8050;
     GL_RGB8 = $8051;
     GL_RGB10 = $8052;
     GL_RGB12 = $8053;
     GL_RGB16 = $8054;
     GL_RGBA2 = $8055;
     GL_RGBA4 = $8056;
     GL_RGB5_A1 = $8057;
     GL_RGBA8 = $8058;
     GL_RGB10_A2 = $8059;
     GL_RGBA12 = $805A;
     GL_RGBA16 = $805B;
  {      GL_COLOR_INDEX1_EXT  }
  {      GL_COLOR_INDEX2_EXT  }
  {      GL_COLOR_INDEX4_EXT  }
  {      GL_COLOR_INDEX8_EXT  }
  {      GL_COLOR_INDEX12_EXT  }
  {      GL_COLOR_INDEX16_EXT  }
  { InterleavedArrayFormat  }
     GL_V2F = $2A20;
     GL_V3F = $2A21;
     GL_C4UB_V2F = $2A22;
     GL_C4UB_V3F = $2A23;
     GL_C3F_V3F = $2A24;
     GL_N3F_V3F = $2A25;
     GL_C4F_N3F_V3F = $2A26;
     GL_T2F_V3F = $2A27;
     GL_T4F_V4F = $2A28;
     GL_T2F_C4UB_V3F = $2A29;
     GL_T2F_C3F_V3F = $2A2A;
     GL_T2F_N3F_V3F = $2A2B;
     GL_T2F_C4F_N3F_V3F = $2A2C;
     GL_T4F_C4F_N3F_V4F = $2A2D;
  { VertexPointerType  }
  {      GL_SHORT  }
  {      GL_INT  }
  {      GL_FLOAT  }
  {      GL_DOUBLE  }
  { ClipPlaneName  }
     GL_CLIP_PLANE0 = $3000;
     GL_CLIP_PLANE1 = $3001;
     GL_CLIP_PLANE2 = $3002;
     GL_CLIP_PLANE3 = $3003;
     GL_CLIP_PLANE4 = $3004;
     GL_CLIP_PLANE5 = $3005;
  { LightName  }
     GL_LIGHT0 = $4000;
     GL_LIGHT1 = $4001;
     GL_LIGHT2 = $4002;
     GL_LIGHT3 = $4003;
     GL_LIGHT4 = $4004;
     GL_LIGHT5 = $4005;
     GL_LIGHT6 = $4006;
     GL_LIGHT7 = $4007;
  { EXT_abgr  }
     GL_ABGR_EXT = $8000;
  { EXT_blend_color  }
     GL_CONSTANT_COLOR_EXT = $8001;
     GL_ONE_MINUS_CONSTANT_COLOR_EXT = $8002;
     GL_CONSTANT_ALPHA_EXT = $8003;
     GL_ONE_MINUS_CONSTANT_ALPHA_EXT = $8004;
     GL_BLEND_COLOR_EXT = $8005;
  { EXT_blend_minmax  }
     GL_FUNC_ADD_EXT = $8006;
     GL_MIN_EXT = $8007;
     GL_MAX_EXT = $8008;
     GL_BLEND_EQUATION_EXT = $8009;
  { EXT_blend_subtract  }
     GL_FUNC_SUBTRACT_EXT = $800A;
     GL_FUNC_REVERSE_SUBTRACT_EXT = $800B;
  { EXT_packed_pixels  }
     GL_UNSIGNED_BYTE_3_3_2_EXT = $8032;
     GL_UNSIGNED_SHORT_4_4_4_4_EXT = $8033;
     GL_UNSIGNED_SHORT_5_5_5_1_EXT = $8034;
     GL_UNSIGNED_INT_8_8_8_8_EXT = $8035;
     GL_UNSIGNED_INT_10_10_10_2_EXT = $8036;
  { OpenGL12  }
     GL_PACK_SKIP_IMAGES = $806B;
     GL_PACK_IMAGE_HEIGHT = $806C;
     GL_UNPACK_SKIP_IMAGES = $806D;
     GL_UNPACK_IMAGE_HEIGHT = $806E;
     GL_TEXTURE_3D = $806F;
     GL_PROXY_TEXTURE_3D = $8070;
     GL_TEXTURE_DEPTH = $8071;
     GL_TEXTURE_WRAP_R = $8072;
     GL_MAX_3D_TEXTURE_SIZE = $8073;
     GL_BGR = $80E0;
     GL_BGRA = $80E1;
     GL_UNSIGNED_BYTE_3_3_2 = $8032;
     GL_UNSIGNED_BYTE_2_3_3_REV = $8362;
     GL_UNSIGNED_SHORT_5_6_5 = $8363;
     GL_UNSIGNED_SHORT_5_6_5_REV = $8364;
     GL_UNSIGNED_SHORT_4_4_4_4 = $8033;
     GL_UNSIGNED_SHORT_4_4_4_4_REV = $8365;
     GL_UNSIGNED_SHORT_5_5_5_1 = $8034;
     GL_UNSIGNED_SHORT_1_5_5_5_REV = $8366;
     GL_UNSIGNED_INT_8_8_8_8 = $8035;
     GL_UNSIGNED_INT_8_8_8_8_REV = $8367;
     GL_UNSIGNED_INT_10_10_10_2 = $8036;
     GL_UNSIGNED_INT_2_10_10_10_REV = $8368;
     GL_RESCALE_NORMAL = $803A;
     GL_LIGHT_MODEL_COLOR_CONTROL = $81F8;
     GL_SINGLE_COLOR = $81F9;
     GL_SEPARATE_SPECULAR_COLOR = $81FA;
     GL_CLAMP_TO_EDGE = $812F;
     GL_TEXTURE_MIN_LOD = $813A;
     GL_TEXTURE_MAX_LOD = $813B;
     GL_TEXTURE_BASE_LEVEL = $813C;
     GL_TEXTURE_MAX_LEVEL = $813D;
     GL_MAX_ELEMENTS_VERTICES = $80E8;
     GL_MAX_ELEMENTS_INDICES = $80E9;
     GL_ALIASED_POINT_SIZE_RANGE = $846D;
     GL_ALIASED_LINE_WIDTH_RANGE = $846E;
  { ARB_imaging  }
     GL_CONSTANT_COLOR = $8001;
     GL_ONE_MINUS_CONSTANT_COLOR = $8002;
     GL_CONSTANT_ALPHA = $8003;
     GL_ONE_MINUS_CONSTANT_ALPHA = $8004;
     GL_BLEND_COLOR = $8005;
     GL_FUNC_ADD = $8006;
     GL_MIN = $8007;
     GL_MAX = $8008;
     GL_BLEND_EQUATION = $8009;
     GL_FUNC_SUBTRACT = $800A;
     GL_FUNC_REVERSE_SUBTRACT = $800B;
     GL_COLOR_MATRIX = $80B1;
     GL_COLOR_MATRIX_STACK_DEPTH = $80B2;
     GL_MAX_COLOR_MATRIX_STACK_DEPTH = $80B3;
     GL_POST_COLOR_MATRIX_RED_SCALE = $80B4;
     GL_POST_COLOR_MATRIX_GREEN_SCALE = $80B5;
     GL_POST_COLOR_MATRIX_BLUE_SCALE = $80B6;
     GL_POST_COLOR_MATRIX_ALPHA_SCALE = $80B7;
     GL_POST_COLOR_MATRIX_RED_BIAS = $80B8;
     GL_POST_COLOR_MATRIX_GREEN_BIAS = $80B9;
     GL_POST_COLOR_MATRIX_BLUE_BIAS = $80BA;
     GL_POST_COLOR_MATRIX_ALPHA_BIAS = $80BB;
     GL_COLOR_TABLE = $80D0;
     GL_POST_CONVOLUTION_COLOR_TABLE = $80D1;
     GL_POST_COLOR_MATRIX_COLOR_TABLE = $80D2;
     GL_PROXY_COLOR_TABLE = $80D3;
     GL_PROXY_POST_CONVOLUTION_COLOR_TABLE = $80D4;
     GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE = $80D5;
     GL_COLOR_TABLE_SCALE = $80D6;
     GL_COLOR_TABLE_BIAS = $80D7;
     GL_COLOR_TABLE_FORMAT = $80D8;
     GL_COLOR_TABLE_WIDTH = $80D9;
     GL_COLOR_TABLE_RED_SIZE = $80DA;
     GL_COLOR_TABLE_GREEN_SIZE = $80DB;
     GL_COLOR_TABLE_BLUE_SIZE = $80DC;
     GL_COLOR_TABLE_ALPHA_SIZE = $80DD;
     GL_COLOR_TABLE_LUMINANCE_SIZE = $80DE;
     GL_COLOR_TABLE_INTENSITY_SIZE = $80DF;
     GL_CONVOLUTION_1D = $8010;
     GL_CONVOLUTION_2D = $8011;
     GL_SEPARABLE_2D = $8012;
     GL_CONVOLUTION_BORDER_MODE = $8013;
     GL_CONVOLUTION_FILTER_SCALE = $8014;
     GL_CONVOLUTION_FILTER_BIAS = $8015;
     GL_REDUCE = $8016;
     GL_CONVOLUTION_FORMAT = $8017;
     GL_CONVOLUTION_WIDTH = $8018;
     GL_CONVOLUTION_HEIGHT = $8019;
     GL_MAX_CONVOLUTION_WIDTH = $801A;
     GL_MAX_CONVOLUTION_HEIGHT = $801B;
     GL_POST_CONVOLUTION_RED_SCALE = $801C;
     GL_POST_CONVOLUTION_GREEN_SCALE = $801D;
     GL_POST_CONVOLUTION_BLUE_SCALE = $801E;
     GL_POST_CONVOLUTION_ALPHA_SCALE = $801F;
     GL_POST_CONVOLUTION_RED_BIAS = $8020;
     GL_POST_CONVOLUTION_GREEN_BIAS = $8021;
     GL_POST_CONVOLUTION_BLUE_BIAS = $8022;
     GL_POST_CONVOLUTION_ALPHA_BIAS = $8023;
     GL_IGNORE_BORDER = $8150;
     GL_CONSTANT_BORDER = $8151;
     GL_REPLICATE_BORDER = $8153;
     GL_CONVOLUTION_BORDER_COLOR = $8154;
     GL_HISTOGRAM = $8024;
     GL_PROXY_HISTOGRAM = $8025;
     GL_HISTOGRAM_WIDTH = $8026;
     GL_HISTOGRAM_FORMAT = $8027;
     GL_HISTOGRAM_RED_SIZE = $8028;
     GL_HISTOGRAM_GREEN_SIZE = $8029;
     GL_HISTOGRAM_BLUE_SIZE = $802A;
     GL_HISTOGRAM_ALPHA_SIZE = $802B;
     GL_HISTOGRAM_LUMINANCE_SIZE = $802C;
     GL_HISTOGRAM_SINK = $802D;
     GL_MINMAX = $802E;
     GL_MINMAX_FORMAT = $802F;
     GL_MINMAX_SINK = $8030;
  { OpenGL13 }
     GL_ACTIVE_TEXTURE  = $84E0;
     GL_CLIENT_ACTIVE_TEXTURE = $84E1;
     GL_MAX_TEXTURE_UNITS = $84E2;
     GL_TEXTURE0 = $84C0;
     GL_TEXTURE1 = $84C1;
     GL_TEXTURE2 = $84C2;
     GL_TEXTURE3 = $84C3;
     GL_TEXTURE4 = $84C4;
     GL_TEXTURE5 = $84C5;
     GL_TEXTURE6 = $84C6;
     GL_TEXTURE7 = $84C7;
     GL_TEXTURE8 = $84C8;
     GL_TEXTURE9 = $84C9;
     GL_TEXTURE10 = $84CA;
     GL_TEXTURE11 = $84CB;
     GL_TEXTURE12 = $84CC;
     GL_TEXTURE13 = $84CD;
     GL_TEXTURE14 = $84CE;
     GL_TEXTURE15 = $84CF;
     GL_TEXTURE16 = $84D0;
     GL_TEXTURE17 = $84D1;
     GL_TEXTURE18 = $84D2;
     GL_TEXTURE19 = $84D3;
     GL_TEXTURE20 = $84D4;
     GL_TEXTURE21 = $84D5;
     GL_TEXTURE22 = $84D6;
     GL_TEXTURE23 = $84D7;
     GL_TEXTURE24 = $84D8;
     GL_TEXTURE25 = $84D9;
     GL_TEXTURE26 = $84DA;
     GL_TEXTURE27 = $84DB;
     GL_TEXTURE28 = $84DC;
     GL_TEXTURE29 = $84DD;
     GL_TEXTURE30 = $84DE;
     GL_TEXTURE31 = $84DF;
     GL_NORMAL_MAP = $8511;
     GL_REFLECTION_MAP = $8512;
     GL_TEXTURE_CUBE_MAP = $8513;
     GL_TEXTURE_BINDING_CUBE_MAP = $8514;
     GL_TEXTURE_CUBE_MAP_POSITIVE_X = $8515;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_X = $8516;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Y = $8517;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = $8518;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Z = $8519;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = $851A;
     GL_PROXY_TEXTURE_CUBE_MAP = $851B;
     GL_MAX_CUBE_MAP_TEXTURE_SIZE = $851C;
     GL_COMBINE = $8570;
     GL_COMBINE_RGB = $8571;
     GL_COMBINE_ALPHA = $8572;
     GL_RGB_SCALE = $8573;
     GL_ADD_SIGNED = $8574;
     GL_INTERPOLATE = $8575;
     GL_CONSTANT = $8576;
     GL_PRIMARY_COLOR = $8577;
     GL_PREVIOUS = $8578;
     GL_SOURCE0_RGB = $8580;
     GL_SOURCE1_RGB = $8581;
     GL_SOURCE2_RGB = $8582;
     GL_SOURCE0_ALPHA = $8588;
     GL_SOURCE1_ALPHA = $8589;
     GL_SOURCE2_ALPHA = $858A;
     GL_OPERAND0_RGB = $8590;
     GL_OPERAND1_RGB = $8591;
     GL_OPERAND2_RGB = $8592;
     GL_OPERAND0_ALPHA = $8598;
     GL_OPERAND1_ALPHA = $8599;
     GL_OPERAND2_ALPHA = $859A;
     GL_SUBTRACT = $84E7;
     GL_TRANSPOSE_MODELVIEW_MATRIX = $84E3;
     GL_TRANSPOSE_PROJECTION_MATRIX = $84E4;
     GL_TRANSPOSE_TEXTURE_MATRIX = $84E5;
     GL_TRANSPOSE_COLOR_MATRIX = $84E6;
     GL_COMPRESSED_ALPHA = $84E9;
     GL_COMPRESSED_LUMINANCE = $84EA;
     GL_COMPRESSED_LUMINANCE_ALPHA = $84EB;
     GL_COMPRESSED_INTENSITY = $84EC;
     GL_COMPRESSED_RGB = $84ED;
     GL_COMPRESSED_RGBA = $84EE;
     GL_TEXTURE_COMPRESSION_HINT = $84EF;
     GL_TEXTURE_COMPRESSED_IMAGE_SIZE = $86A0;
     GL_TEXTURE_COMPRESSED = $86A1;
     GL_NUM_COMPRESSED_TEXTURE_FORMATS = $86A2;
     GL_COMPRESSED_TEXTURE_FORMATS = $86A3;
     GL_DOT3_RGB = $86AE;
     GL_DOT3_RGBA = $86AF;
     GL_CLAMP_TO_BORDER = $812D;
     GL_MULTISAMPLE = $809D;
     GL_SAMPLE_ALPHA_TO_COVERAGE = $809E;
     GL_SAMPLE_ALPHA_TO_ONE = $809F;
     GL_SAMPLE_COVERAGE = $80A0;
     GL_SAMPLE_BUFFERS = $80A8;
     GL_SAMPLES = $80A9;
     GL_SAMPLE_COVERAGE_VALUE = $80AA;
     GL_SAMPLE_COVERAGE_INVERT = $80AB;
     GL_MULTISAMPLE_BIT = $20000000;
  { EXT_vertex_array  }
     GL_VERTEX_ARRAY_EXT = $8074;
     GL_NORMAL_ARRAY_EXT = $8075;
     GL_COLOR_ARRAY_EXT = $8076;
     GL_INDEX_ARRAY_EXT = $8077;
     GL_TEXTURE_COORD_ARRAY_EXT = $8078;
     GL_EDGE_FLAG_ARRAY_EXT = $8079;
     GL_VERTEX_ARRAY_SIZE_EXT = $807A;
     GL_VERTEX_ARRAY_TYPE_EXT = $807B;
     GL_VERTEX_ARRAY_STRIDE_EXT = $807C;
     GL_VERTEX_ARRAY_COUNT_EXT = $807D;
     GL_NORMAL_ARRAY_TYPE_EXT = $807E;
     GL_NORMAL_ARRAY_STRIDE_EXT = $807F;
     GL_NORMAL_ARRAY_COUNT_EXT = $8080;
     GL_COLOR_ARRAY_SIZE_EXT = $8081;
     GL_COLOR_ARRAY_TYPE_EXT = $8082;
     GL_COLOR_ARRAY_STRIDE_EXT = $8083;
     GL_COLOR_ARRAY_COUNT_EXT = $8084;
     GL_INDEX_ARRAY_TYPE_EXT = $8085;
     GL_INDEX_ARRAY_STRIDE_EXT = $8086;
     GL_INDEX_ARRAY_COUNT_EXT = $8087;
     GL_TEXTURE_COORD_ARRAY_SIZE_EXT = $8088;
     GL_TEXTURE_COORD_ARRAY_TYPE_EXT = $8089;
     GL_TEXTURE_COORD_ARRAY_STRIDE_EXT = $808A;
     GL_TEXTURE_COORD_ARRAY_COUNT_EXT = $808B;
     GL_EDGE_FLAG_ARRAY_STRIDE_EXT = $808C;
     GL_EDGE_FLAG_ARRAY_COUNT_EXT = $808D;
     GL_VERTEX_ARRAY_POINTER_EXT = $808E;
     GL_NORMAL_ARRAY_POINTER_EXT = $808F;
     GL_COLOR_ARRAY_POINTER_EXT = $8090;
     GL_INDEX_ARRAY_POINTER_EXT = $8091;
     GL_TEXTURE_COORD_ARRAY_POINTER_EXT = $8092;
     GL_EDGE_FLAG_ARRAY_POINTER_EXT = $8093;
  { EXT_texture3D  }
    // GL_PACK_SKIP_IMAGES = $806B;
     GL_PACK_SKIP_IMAGES_EXT = $806B;
    // GL_PACK_IMAGE_HEIGHT = $806C;
     GL_PACK_IMAGE_HEIGHT_EXT = $806C;
    // GL_UNPACK_SKIP_IMAGES = $806D;
     GL_UNPACK_SKIP_IMAGES_EXT = $806D;
    // GL_UNPACK_IMAGE_HEIGHT = $806E;
     GL_UNPACK_IMAGE_HEIGHT_EXT = $806E;
    // GL_TEXTURE_3D = $806F;
     GL_TEXTURE_3D_EXT = $806F;
    // GL_PROXY_TEXTURE_3D = $8070;
     GL_PROXY_TEXTURE_3D_EXT = $8070;
    // GL_TEXTURE_DEPTH = $8071;
     GL_TEXTURE_DEPTH_EXT = $8071;
    // GL_TEXTURE_WRAP_R = $8072;
     GL_TEXTURE_WRAP_R_EXT = $8072;
    // GL_MAX_3D_TEXTURE_SIZE = $8073;
     GL_MAX_3D_TEXTURE_SIZE_EXT = $8073;
  { EXT_color_table  }
     GL_TABLE_TOO_LARGE_EXT = $8031;
     GL_COLOR_TABLE_FORMAT_EXT = $80D8;
     GL_COLOR_TABLE_WIDTH_EXT = $80D9;
     GL_COLOR_TABLE_RED_SIZE_EXT = $80DA;
     GL_COLOR_TABLE_GREEN_SIZE_EXT = $80DB;
     GL_COLOR_TABLE_BLUE_SIZE_EXT = $80DC;
     GL_COLOR_TABLE_ALPHA_SIZE_EXT = $80DD;
     GL_COLOR_TABLE_LUMINANCE_SIZE_EXT = $80DE;
     GL_COLOR_TABLE_INTENSITY_SIZE_EXT = $80DF;
  { EXT_bgra  }
     GL_BGR_EXT = $80E0;
     GL_BGRA_EXT = $80E1;
  { SGIS_texture_lod  }
     GL_TEXTURE_MIN_LOD_SGIS = $813A;
     GL_TEXTURE_MAX_LOD_SGIS = $813B;
     GL_TEXTURE_BASE_LEVEL_SGIS = $813C;
     GL_TEXTURE_MAX_LEVEL_SGIS = $813D;
  { EXT_paletted_texture  }
     GL_COLOR_INDEX1_EXT = $80E2;
     GL_COLOR_INDEX2_EXT = $80E3;
     GL_COLOR_INDEX4_EXT = $80E4;
     GL_COLOR_INDEX8_EXT = $80E5;
     GL_COLOR_INDEX12_EXT = $80E6;
     GL_COLOR_INDEX16_EXT = $80E7;
     GL_TEXTURE_INDEX_SIZE_EXT = $80ED;
  { EXT_clip_volume_hint }
     GL_CLIP_VOLUME_CLIPPING_HINT_EXT = $80F0;
  { EXT_point_parameters  }
     GL_POINT_SIZE_MIN_EXT = $8126;
     GL_POINT_SIZE_MAX_EXT = $8127;
     GL_POINT_FADE_THRESHOLD_SIZE_EXT = $8128;
     GL_DISTANCE_ATTENUATION_EXT = $8129;
  { EXT_compiled_vertex_array  }
     GL_ARRAY_ELEMENT_LOCK_FIRST_EXT = $81A8;
     GL_ARRAY_ELEMENT_LOCK_COUNT_EXT = $81A9;
  { EXT_shared_texture_palette  }
     GL_SHARED_TEXTURE_PALETTE_EXT = $81FB;
  { SGIS_multitexture  }
     GL_SELECTED_TEXTURE_SGIS = $835C;
     GL_MAX_TEXTURES_SGIS = $835D;
     GL_TEXTURE0_SGIS = $835E;
     GL_TEXTURE1_SGIS = $835F;
     GL_TEXTURE2_SGIS = $8360;
     GL_TEXTURE3_SGIS = $8361;
  { ARB_multitexture  }
     GL_ACTIVE_TEXTURE_ARB = $84E0;
     GL_CLIENT_ACTIVE_TEXTURE_ARB = $84E1;
     GL_MAX_TEXTURE_UNITS_ARB = $84E2;
     GL_TEXTURE0_ARB = $84C0;
     GL_TEXTURE1_ARB = $84C1;
     GL_TEXTURE2_ARB = $84C2;
     GL_TEXTURE3_ARB = $84C3;
     GL_TEXTURE4_ARB = $84C4;
     GL_TEXTURE5_ARB = $84C5;
     GL_TEXTURE6_ARB = $84C6;
     GL_TEXTURE7_ARB = $84C7;
     GL_TEXTURE8_ARB = $84C8;
     GL_TEXTURE9_ARB = $84C9;
     GL_TEXTURE10_ARB = $84CA;
     GL_TEXTURE11_ARB = $84CB;
     GL_TEXTURE12_ARB = $84CC;
     GL_TEXTURE13_ARB = $84CD;
     GL_TEXTURE14_ARB = $84CE;
     GL_TEXTURE15_ARB = $84CF;
     GL_TEXTURE16_ARB = $84D0;
     GL_TEXTURE17_ARB = $84D1;
     GL_TEXTURE18_ARB = $84D2;
     GL_TEXTURE19_ARB = $84D3;
     GL_TEXTURE20_ARB = $84D4;
     GL_TEXTURE21_ARB = $84D5;
     GL_TEXTURE22_ARB = $84D6;
     GL_TEXTURE23_ARB = $84D7;
     GL_TEXTURE24_ARB = $84D8;
     GL_TEXTURE25_ARB = $84D9;
     GL_TEXTURE26_ARB = $84DA;
     GL_TEXTURE27_ARB = $84DB;
     GL_TEXTURE28_ARB = $84DC;
     GL_TEXTURE29_ARB = $84DD;
     GL_TEXTURE30_ARB = $84DE;
     GL_TEXTURE31_ARB = $84DF;
  { EXT_fog_coord  }
     GL_FOG_COORDINATE_SOURCE_EXT = $8450;
     GL_FOG_COORDINATE_EXT = $8451;
     GL_FRAGMENT_DEPTH_EXT = $8452;
     GL_CURRENT_FOG_COORDINATE_EXT = $8453;
     GL_FOG_COORDINATE_ARRAY_TYPE_EXT = $8454;
     GL_FOG_COORDINATE_ARRAY_STRIDE_EXT = $8455;
     GL_FOG_COORDINATE_ARRAY_POINTER_EXT = $8456;
     GL_FOG_COORDINATE_ARRAY_EXT = $8457;
  { EXT_secondary_color  }
     GL_COLOR_SUM_EXT = $8458;
     GL_CURRENT_SECONDARY_COLOR_EXT = $8459;
     GL_SECONDARY_COLOR_ARRAY_SIZE_EXT = $845A;
     GL_SECONDARY_COLOR_ARRAY_TYPE_EXT = $845B;
     GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT = $845C;
     GL_SECONDARY_COLOR_ARRAY_POINTER_EXT = $845D;
     GL_SECONDARY_COLOR_ARRAY_EXT = $845E;
  { EXT_separate_specular_color  }
     GL_SINGLE_COLOR_EXT = $81F9;
     GL_SEPARATE_SPECULAR_COLOR_EXT = $81FA;
     GL_LIGHT_MODEL_COLOR_CONTROL_EXT = $81F8;
  { EXT_rescale_normal  }
     GL_RESCALE_NORMAL_EXT = $803A;
  { EXT_stencil_wrap  }
     GL_INCR_WRAP_EXT = $8507;
     GL_DECR_WRAP_EXT = $8508;
  { EXT_vertex_weighting  }
     GL_MODELVIEW0_MATRIX_EXT = GL_MODELVIEW_MATRIX;
     GL_MODELVIEW1_MATRIX_EXT = $8506;
     GL_MODELVIEW0_STACK_DEPTH_EXT = GL_MODELVIEW_STACK_DEPTH;
     GL_MODELVIEW1_STACK_DEPTH_EXT = $8502;
     GL_VERTEX_WEIGHTING_EXT = $8509;
     GL_MODELVIEW0_EXT = GL_MODELVIEW;
     GL_MODELVIEW1_EXT = $850A;
     GL_CURRENT_VERTEX_WEIGHT_EXT = $850B;
     GL_VERTEX_WEIGHT_ARRAY_EXT = $850C;
     GL_VERTEX_WEIGHT_ARRAY_SIZE_EXT = $850D;
     GL_VERTEX_WEIGHT_ARRAY_TYPE_EXT = $850E;
     GL_VERTEX_WEIGHT_ARRAY_STRIDE_EXT = $850F;
     GL_VERTEX_WEIGHT_ARRAY_POINTER_EXT = $8510;
  { NV_texgen_reflection  }
     GL_NORMAL_MAP_NV = $8511;
     GL_REFLECTION_MAP_NV = $8512;
  { EXT_texture_cube_map  }
     GL_NORMAL_MAP_EXT = $8511;
     GL_REFLECTION_MAP_EXT = $8512;
     GL_TEXTURE_CUBE_MAP_EXT = $8513;
     GL_TEXTURE_BINDING_CUBE_MAP_EXT = $8514;
     GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT = $8515;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT = $8516;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT = $8517;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT = $8518;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT = $8519;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT = $851A;
     GL_PROXY_TEXTURE_CUBE_MAP_EXT = $851B;
     GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT = $851C;
  { ARB_texture_cube_map  }
     GL_NORMAL_MAP_ARB = $8511;
     GL_REFLECTION_MAP_ARB = $8512;
     GL_TEXTURE_CUBE_MAP_ARB = $8513;
     GL_TEXTURE_BINDING_CUBE_MAP_ARB = $8514;
     GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB = $8515;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB = $8516;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB = $8517;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB = $8518;
     GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB = $8519;
     GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB = $851A;
     GL_PROXY_TEXTURE_CUBE_MAP_ARB = $851B;
     GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB = $851C;
  { NV_vertex_array_range  }
     GL_VERTEX_ARRAY_RANGE_NV = $851D;
     GL_VERTEX_ARRAY_RANGE_LENGTH_NV = $851E;
     GL_VERTEX_ARRAY_RANGE_VALID_NV = $851F;
     GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV = $8520;
     GL_VERTEX_ARRAY_RANGE_POINTER_NV = $8521;
  { NV_vertex_array_range2  }
     GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV = $8533;
  { NV_register_combiners  }
     GL_REGISTER_COMBINERS_NV = $8522;
     GL_COMBINER0_NV = $8550;
     GL_COMBINER1_NV = $8551;
     GL_COMBINER2_NV = $8552;
     GL_COMBINER3_NV = $8553;
     GL_COMBINER4_NV = $8554;
     GL_COMBINER5_NV = $8555;
     GL_COMBINER6_NV = $8556;
     GL_COMBINER7_NV = $8557;
     GL_VARIABLE_A_NV = $8523;
     GL_VARIABLE_B_NV = $8524;
     GL_VARIABLE_C_NV = $8525;
     GL_VARIABLE_D_NV = $8526;
     GL_VARIABLE_E_NV = $8527;
     GL_VARIABLE_F_NV = $8528;
     GL_VARIABLE_G_NV = $8529;
  {      GL_ZERO  }
     GL_CONSTANT_COLOR0_NV = $852A;
     GL_CONSTANT_COLOR1_NV = $852B;
  {      GL_FOG  }
     GL_PRIMARY_COLOR_NV = $852C;
     GL_SECONDARY_COLOR_NV = $852D;
     GL_SPARE0_NV = $852E;
     GL_SPARE1_NV = $852F;
  {      GL_TEXTURE0_ARB  }
  {      GL_TEXTURE1_ARB  }
     GL_UNSIGNED_IDENTITY_NV = $8536;
     GL_UNSIGNED_INVERT_NV = $8537;
     GL_EXPAND_NORMAL_NV = $8538;
     GL_EXPAND_NEGATE_NV = $8539;
     GL_HALF_BIAS_NORMAL_NV = $853A;
     GL_HALF_BIAS_NEGATE_NV = $853B;
     GL_SIGNED_IDENTITY_NV = $853C;
     GL_SIGNED_NEGATE_NV = $853D;
     GL_E_TIMES_F_NV = $8531;
     GL_SPARE0_PLUS_SECONDARY_COLOR_NV = $8532;
  {      GL_NONE  }
     GL_SCALE_BY_TWO_NV = $853E;
     GL_SCALE_BY_FOUR_NV = $853F;
     GL_SCALE_BY_ONE_HALF_NV = $8540;
     GL_BIAS_BY_NEGATIVE_ONE_HALF_NV = $8541;
     GL_DISCARD_NV = $8530;
     GL_COMBINER_INPUT_NV = $8542;
     GL_COMBINER_MAPPING_NV = $8543;
     GL_COMBINER_COMPONENT_USAGE_NV = $8544;
     GL_COMBINER_AB_DOT_PRODUCT_NV = $8545;
     GL_COMBINER_CD_DOT_PRODUCT_NV = $8546;
     GL_COMBINER_MUX_SUM_NV = $8547;
     GL_COMBINER_SCALE_NV = $8548;
     GL_COMBINER_BIAS_NV = $8549;
     GL_COMBINER_AB_OUTPUT_NV = $854A;
     GL_COMBINER_CD_OUTPUT_NV = $854B;
     GL_COMBINER_SUM_OUTPUT_NV = $854C;
     GL_MAX_GENERAL_COMBINERS_NV = $854D;
     GL_NUM_GENERAL_COMBINERS_NV = $854E;
     GL_COLOR_SUM_CLAMP_NV = $854F;
  { NV_fog_distance  }
     GL_FOG_DISTANCE_MODE_NV = $855A;
     GL_EYE_RADIAL_NV = $855B;
  {      GL_EYE_PLANE  }
     GL_EYE_PLANE_ABSOLUTE_NV = $855C;
  { NV_fragment_program }
     GL_FRAGMENT_PROGRAM_NV = $8870;
     GL_MAX_TEXTURE_COORDS_NV = $8871;
     GL_MAX_TEXTURE_IMAGE_UNITS_NV = $8872;
  { NV_texgen_emboss  }
     GL_EMBOSS_LIGHT_NV = $855D;
     GL_EMBOSS_CONSTANT_NV = $855E;
     GL_EMBOSS_MAP_NV = $855F;
  { NV_light_max_exponent  }
     GL_MAX_SHININESS_NV = $8504;
     GL_MAX_SPOT_EXPONENT_NV = $8505;
  { ARB_texture_env_combine  }
     GL_COMBINE_ARB = $8570;
     GL_COMBINE_RGB_ARB = $8571;
     GL_COMBINE_ALPHA_ARB = $8572;
     GL_RGB_SCALE_ARB = $8573;
     GL_ADD_SIGNED_ARB = $8574;
     GL_INTERPOLATE_ARB = $8575;
     GL_CONSTANT_ARB = $8576;
     GL_PRIMARY_COLOR_ARB = $8577;
     GL_PREVIOUS_ARB = $8578;
     GL_SOURCE0_RGB_ARB = $8580;
     GL_SOURCE1_RGB_ARB = $8581;
     GL_SOURCE2_RGB_ARB = $8582;
     GL_SOURCE0_ALPHA_ARB = $8588;
     GL_SOURCE1_ALPHA_ARB = $8589;
     GL_SOURCE2_ALPHA_ARB = $858A;
     GL_OPERAND0_RGB_ARB = $8590;
     GL_OPERAND1_RGB_ARB = $8591;
     GL_OPERAND2_RGB_ARB = $8592;
     GL_OPERAND0_ALPHA_ARB = $8598;
     GL_OPERAND1_ALPHA_ARB = $8599;
     GL_OPERAND2_ALPHA_ARB = $859A;
     GL_SUBTRACT_ARB = $84E7;
  { EXT_texture_env_combine  }
     GL_COMBINE_EXT = $8570;
     GL_COMBINE_RGB_EXT = $8571;
     GL_COMBINE_ALPHA_EXT = $8572;
     GL_RGB_SCALE_EXT = $8573;
     GL_ADD_SIGNED_EXT = $8574;
     GL_INTERPOLATE_EXT = $8575;
     GL_CONSTANT_EXT = $8576;
     GL_PRIMARY_COLOR_EXT = $8577;
     GL_PREVIOUS_EXT = $8578;
     GL_SOURCE0_RGB_EXT = $8580;
     GL_SOURCE1_RGB_EXT = $8581;
     GL_SOURCE2_RGB_EXT = $8582;
     GL_SOURCE0_ALPHA_EXT = $8588;
     GL_SOURCE1_ALPHA_EXT = $8589;
     GL_SOURCE2_ALPHA_EXT = $858A;
     GL_OPERAND0_RGB_EXT = $8590;
     GL_OPERAND1_RGB_EXT = $8591;
     GL_OPERAND2_RGB_EXT = $8592;
     GL_OPERAND0_ALPHA_EXT = $8598;
     GL_OPERAND1_ALPHA_EXT = $8599;
     GL_OPERAND2_ALPHA_EXT = $859A;
  { NV_texture_env_combine4  }
     GL_COMBINE4_NV = $8503;
     GL_SOURCE3_RGB_NV = $8583;
     GL_SOURCE3_ALPHA_NV = $858B;
     GL_OPERAND3_RGB_NV = $8593;
     GL_OPERAND3_ALPHA_NV = $859B;
  { EXT_texture_filter_anisotropic  }
     GL_TEXTURE_MAX_ANISOTROPY_EXT = $84FE;
     GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT = $84FF;
  { EXT_texture_lod_bias  }
     GL_MAX_TEXTURE_LOD_BIAS_EXT = $84FD;
     GL_TEXTURE_FILTER_CONTROL_EXT = $8500;
     GL_TEXTURE_LOD_BIAS_EXT = $8501;
  { EXT_texture_edge_clamp  }
     GL_CLAMP_TO_EDGE_EXT = $812F;
  { S3_s3tc  }
     GL_RGB_S3TC = $83A0;
     GL_RGB4_S3TC = $83A1;
     GL_RGBA_S3TC = $83A2;
     GL_RGBA4_S3TC = $83A3;
  { ARB_transpose_matrix  }
     GL_TRANSPOSE_MODELVIEW_MATRIX_ARB = $84E3;
     GL_TRANSPOSE_PROJECTION_MATRIX_ARB = $84E4;
     GL_TRANSPOSE_TEXTURE_MATRIX_ARB = $84E5;
     GL_TRANSPOSE_COLOR_MATRIX_ARB = $84E6;
  { ARB_texture_compression  }
     GL_COMPRESSED_ALPHA_ARB = $84E9;
     GL_COMPRESSED_LUMINANCE_ARB = $84EA;
     GL_COMPRESSED_LUMINANCE_ALPHA_ARB = $84EB;
     GL_COMPRESSED_INTENSITY_ARB = $84EC;
     GL_COMPRESSED_RGB_ARB = $84ED;
     GL_COMPRESSED_RGBA_ARB = $84EE;
     GL_TEXTURE_COMPRESSION_HINT_ARB = $84EF;
     GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB = $86A0;
     GL_TEXTURE_COMPRESSED_ARB = $86A1;
     GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB = $86A2;
     GL_COMPRESSED_TEXTURE_FORMATS_ARB = $86A3;
  { EXT_texture_compression_s3tc  }
     GL_COMPRESSED_RGB_S3TC_DXT1_EXT = $83F0;
     GL_COMPRESSED_RGBA_S3TC_DXT1_EXT = $83F1;
     GL_COMPRESSED_RGBA_S3TC_DXT3_EXT = $83F2;
     GL_COMPRESSED_RGBA_S3TC_DXT5_EXT = $83F3;
  { NV_fence  }
     GL_ALL_COMPLETED_NV = $84F2;
     GL_FENCE_STATUS_NV = $84F3;
     GL_FENCE_CONDITION_NV = $84F4;
  { NV_mac_get_proc_address  }
     GL_ALL_EXTENSIONS_NV = $84FB;
     GL_MAC_GET_PROC_ADDRESS_NV = $84FC;
  { NV_vertex_program  }
     GL_VERTEX_PROGRAM_NV = $8620;
     GL_VERTEX_STATE_PROGRAM_NV = $8621;
     GL_ATTRIB_ARRAY_SIZE_NV = $8623;
     GL_ATTRIB_ARRAY_STRIDE_NV = $8624;
     GL_ATTRIB_ARRAY_TYPE_NV = $8625;
     GL_CURRENT_ATTRIB_NV = $8626;
     GL_PROGRAM_LENGTH_NV = $8627;
     GL_PROGRAM_STRING_NV = $8628;
     GL_MODELVIEW_PROJECTION_NV = $8629;
     GL_IDENTITY_NV = $862A;
     GL_INVERSE_NV = $862B;
     GL_TRANSPOSE_NV = $862C;
     GL_INVERSE_TRANSPOSE_NV = $862D;
     GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV = $862E;
     GL_MAX_TRACK_MATRICES_NV = $862F;
     GL_MATRIX0_NV = $8630;
     GL_MATRIX1_NV = $8631;
     GL_MATRIX2_NV = $8632;
     GL_MATRIX3_NV = $8633;
     GL_MATRIX4_NV = $8634;
     GL_MATRIX5_NV = $8635;
     GL_MATRIX6_NV = $8636;
     GL_MATRIX7_NV = $8637;
     GL_CURRENT_MATRIX_STACK_DEPTH_NV = $8640;
     GL_CURRENT_MATRIX_NV = $8641;
     GL_VERTEX_PROGRAM_POINT_SIZE_NV = $8642;
     GL_VERTEX_PROGRAM_TWO_SIDE_NV = $8643;
     GL_PROGRAM_PARAMETER_NV = $8644;
     GL_ATTRIB_ARRAY_POINTER_NV = $8645;
     GL_PROGRAM_TARGET_NV = $8646;
     GL_PROGRAM_RESIDENT_NV = $8647;
     GL_TRACK_MATRIX_NV = $8648;
     GL_TRACK_MATRIX_TRANSFORM_NV = $8649;
     GL_VERTEX_PROGRAM_BINDING_NV = $864A;
     GL_PROGRAM_ERROR_POSITION_NV = $864B;
     GL_VERTEX_ATTRIB_ARRAY0_NV = $8650;
     GL_VERTEX_ATTRIB_ARRAY1_NV = $8651;
     GL_VERTEX_ATTRIB_ARRAY2_NV = $8652;
     GL_VERTEX_ATTRIB_ARRAY3_NV = $8653;
     GL_VERTEX_ATTRIB_ARRAY4_NV = $8654;
     GL_VERTEX_ATTRIB_ARRAY5_NV = $8655;
     GL_VERTEX_ATTRIB_ARRAY6_NV = $8656;
     GL_VERTEX_ATTRIB_ARRAY7_NV = $8657;
     GL_VERTEX_ATTRIB_ARRAY8_NV = $8658;
     GL_VERTEX_ATTRIB_ARRAY9_NV = $8659;
     GL_VERTEX_ATTRIB_ARRAY10_NV = $865A;
     GL_VERTEX_ATTRIB_ARRAY11_NV = $865B;
     GL_VERTEX_ATTRIB_ARRAY12_NV = $865C;
     GL_VERTEX_ATTRIB_ARRAY13_NV = $865D;
     GL_VERTEX_ATTRIB_ARRAY14_NV = $865E;
     GL_VERTEX_ATTRIB_ARRAY15_NV = $865F;
     GL_MAP1_VERTEX_ATTRIB0_4_NV = $8660;
     GL_MAP1_VERTEX_ATTRIB1_4_NV = $8661;
     GL_MAP1_VERTEX_ATTRIB2_4_NV = $8662;
     GL_MAP1_VERTEX_ATTRIB3_4_NV = $8663;
     GL_MAP1_VERTEX_ATTRIB4_4_NV = $8664;
     GL_MAP1_VERTEX_ATTRIB5_4_NV = $8665;
     GL_MAP1_VERTEX_ATTRIB6_4_NV = $8666;
     GL_MAP1_VERTEX_ATTRIB7_4_NV = $8667;
     GL_MAP1_VERTEX_ATTRIB8_4_NV = $8668;
     GL_MAP1_VERTEX_ATTRIB9_4_NV = $8669;
     GL_MAP1_VERTEX_ATTRIB10_4_NV = $866A;
     GL_MAP1_VERTEX_ATTRIB11_4_NV = $866B;
     GL_MAP1_VERTEX_ATTRIB12_4_NV = $866C;
     GL_MAP1_VERTEX_ATTRIB13_4_NV = $866D;
     GL_MAP1_VERTEX_ATTRIB14_4_NV = $866E;
     GL_MAP1_VERTEX_ATTRIB15_4_NV = $866F;
     GL_MAP2_VERTEX_ATTRIB0_4_NV = $8670;
     GL_MAP2_VERTEX_ATTRIB1_4_NV = $8671;
     GL_MAP2_VERTEX_ATTRIB2_4_NV = $8672;
     GL_MAP2_VERTEX_ATTRIB3_4_NV = $8673;
     GL_MAP2_VERTEX_ATTRIB4_4_NV = $8674;
     GL_MAP2_VERTEX_ATTRIB5_4_NV = $8675;
     GL_MAP2_VERTEX_ATTRIB6_4_NV = $8676;
     GL_MAP2_VERTEX_ATTRIB7_4_NV = $8677;
     GL_MAP2_VERTEX_ATTRIB8_4_NV = $8678;
     GL_MAP2_VERTEX_ATTRIB9_4_NV = $8679;
     GL_MAP2_VERTEX_ATTRIB10_4_NV = $867A;
     GL_MAP2_VERTEX_ATTRIB11_4_NV = $867B;
     GL_MAP2_VERTEX_ATTRIB12_4_NV = $867C;
     GL_MAP2_VERTEX_ATTRIB13_4_NV = $867D;
     GL_MAP2_VERTEX_ATTRIB14_4_NV = $867E;
     GL_MAP2_VERTEX_ATTRIB15_4_NV = $867F;
  { NV_evaluators  }
     GL_EVAL_2D_NV = $86C0;
     GL_EVAL_TRIANGULAR_2D_NV = $86C1;
     GL_MAP_TESSELLATION_NV = $86C2;
     GL_MAP_ATTRIB_U_ORDER_NV = $86C3;
     GL_MAP_ATTRIB_V_ORDER_NV = $86C4;
     GL_EVAL_FRACTIONAL_TESSELLATION_NV = $86C5;
     GL_EVAL_VERTEX_ATTRIB0_NV = $86C6;
     GL_EVAL_VERTEX_ATTRIB1_NV = $86C7;
     GL_EVAL_VERTEX_ATTRIB2_NV = $86C8;
     GL_EVAL_VERTEX_ATTRIB3_NV = $86C9;
     GL_EVAL_VERTEX_ATTRIB4_NV = $86CA;
     GL_EVAL_VERTEX_ATTRIB5_NV = $86CB;
     GL_EVAL_VERTEX_ATTRIB6_NV = $86CC;
     GL_EVAL_VERTEX_ATTRIB7_NV = $86CD;
     GL_EVAL_VERTEX_ATTRIB8_NV = $86CE;
     GL_EVAL_VERTEX_ATTRIB9_NV = $86CF;
     GL_EVAL_VERTEX_ATTRIB10_NV = $86D0;
     GL_EVAL_VERTEX_ATTRIB11_NV = $86D1;
     GL_EVAL_VERTEX_ATTRIB12_NV = $86D2;
     GL_EVAL_VERTEX_ATTRIB13_NV = $86D3;
     GL_EVAL_VERTEX_ATTRIB14_NV = $86D4;
     GL_EVAL_VERTEX_ATTRIB15_NV = $86D5;
     GL_MAX_MAP_TESSELLATION_NV = $86D6;
     GL_MAX_RATIONAL_EVAL_ORDER_NV = $86D7;
  { NV_texture_shader  }
     GL_OFFSET_TEXTURE_RECTANGLE_NV = $864C;
     GL_OFFSET_TEXTURE_RECTANGLE_SCALE_NV = $864D;
     GL_DOT_PRODUCT_TEXTURE_RECTANGLE_NV = $864E;
     GL_RGBA_UNSIGNED_DOT_PRODUCT_MAPPING_NV = $86D9;
     GL_UNSIGNED_INT_S8_S8_8_8_NV = $86DA;
     GL_UNSIGNED_INT_8_8_S8_S8_REV_NV = $86DB;
     GL_DSDT_MAG_INTENSITY_NV = $86DC;
     GL_SHADER_CONSISTENT_NV = $86DD;
     GL_TEXTURE_SHADER_NV = $86DE;
     GL_SHADER_OPERATION_NV = $86DF;
     GL_CULL_MODES_NV = $86E0;
     GL_OFFSET_TEXTURE_MATRIX_NV = $86E1;
     GL_OFFSET_TEXTURE_SCALE_NV = $86E2;
     GL_OFFSET_TEXTURE_BIAS_NV = $86E3;
     GL_OFFSET_TEXTURE_2D_MATRIX_NV = GL_OFFSET_TEXTURE_MATRIX_NV;
     GL_OFFSET_TEXTURE_2D_SCALE_NV = GL_OFFSET_TEXTURE_SCALE_NV;
     GL_OFFSET_TEXTURE_2D_BIAS_NV = GL_OFFSET_TEXTURE_BIAS_NV;
     GL_PREVIOUS_TEXTURE_INPUT_NV = $86E4;
     GL_CONST_EYE_NV = $86E5;
     GL_PASS_THROUGH_NV = $86E6;
     GL_CULL_FRAGMENT_NV = $86E7;
     GL_OFFSET_TEXTURE_2D_NV = $86E8;
     GL_DEPENDENT_AR_TEXTURE_2D_NV = $86E9;
     GL_DEPENDENT_GB_TEXTURE_2D_NV = $86EA;
     GL_DOT_PRODUCT_NV = $86EC;
     GL_DOT_PRODUCT_DEPTH_REPLACE_NV = $86ED;
     GL_DOT_PRODUCT_TEXTURE_2D_NV = $86EE;
     GL_DOT_PRODUCT_TEXTURE_CUBE_MAP_NV = $86F0;
     GL_DOT_PRODUCT_DIFFUSE_CUBE_MAP_NV = $86F1;
     GL_DOT_PRODUCT_REFLECT_CUBE_MAP_NV = $86F2;
     GL_DOT_PRODUCT_CONST_EYE_REFLECT_CUBE_MAP_NV = $86F3;
     GL_HILO_NV = $86F4;
     GL_DSDT_NV = $86F5;
     GL_DSDT_MAG_NV = $86F6;
     GL_DSDT_MAG_VIB_NV = $86F7;
     GL_HILO16_NV = $86F8;
     GL_SIGNED_HILO_NV = $86F9;
     GL_SIGNED_HILO16_NV = $86FA;
     GL_SIGNED_RGBA_NV = $86FB;
     GL_SIGNED_RGBA8_NV = $86FC;
     GL_SIGNED_RGB_NV = $86FE;
     GL_SIGNED_RGB8_NV = $86FF;
     GL_SIGNED_LUMINANCE_NV = $8701;
     GL_SIGNED_LUMINANCE8_NV = $8702;
     GL_SIGNED_LUMINANCE_ALPHA_NV = $8703;
     GL_SIGNED_LUMINANCE8_ALPHA8_NV = $8704;
     GL_SIGNED_ALPHA_NV = $8705;
     GL_SIGNED_ALPHA8_NV = $8706;
     GL_SIGNED_INTENSITY_NV = $8707;
     GL_SIGNED_INTENSITY8_NV = $8708;
     GL_DSDT8_NV = $8709;
     GL_DSDT8_MAG8_NV = $870A;
     GL_DSDT8_MAG8_INTENSITY8_NV = $870B;
     GL_SIGNED_RGB_UNSIGNED_ALPHA_NV = $870C;
     GL_SIGNED_RGB8_UNSIGNED_ALPHA8_NV = $870D;
     GL_HI_SCALE_NV = $870E;
     GL_LO_SCALE_NV = $870F;
     GL_DS_SCALE_NV = $8710;
     GL_DT_SCALE_NV = $8711;
     GL_MAGNITUDE_SCALE_NV = $8712;
     GL_VIBRANCE_SCALE_NV = $8713;
     GL_HI_BIAS_NV = $8714;
     GL_LO_BIAS_NV = $8715;
     GL_DS_BIAS_NV = $8716;
     GL_DT_BIAS_NV = $8717;
     GL_MAGNITUDE_BIAS_NV = $8718;
     GL_VIBRANCE_BIAS_NV = $8719;
     GL_TEXTURE_BORDER_VALUES_NV = $871A;
     GL_TEXTURE_HI_SIZE_NV = $871B;
     GL_TEXTURE_LO_SIZE_NV = $871C;
     GL_TEXTURE_DS_SIZE_NV = $871D;
     GL_TEXTURE_DT_SIZE_NV = $871E;
     GL_TEXTURE_MAG_SIZE_NV = $871F;
  { NV_texture_shader2 }
     GL_DOT_PRODUCT_TEXTURE_3D_NV = $86EF;
  { NV_texture_shader3 }
     GL_OFFSET_PROJECTIVE_TEXTURE_2D_NV = $8850;
     GL_OFFSET_PROJECTIVE_TEXTURE_2D_SCALE_NV = $8851;
     GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_NV = $8852;
     GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_SCALE_NV = $8853;
     GL_OFFSET_HILO_TEXTURE_2D_NV = $8854;
     GL_OFFSET_HILO_TEXTURE_RECTANGLE_NV = $8855;
     GL_OFFSET_HILO_PROJECTIVE_TEXTURE_2D_NV = $8856;
     GL_OFFSET_HILO_PROJECTIVE_TEXTURE_RECTANGLE_NV = $8857;
     GL_DEPENDENT_HILO_TEXTURE_2D_NV = $8858;
     GL_DEPENDENT_RGB_TEXTURE_3D_NV = $8859;
     GL_DEPENDENT_RGB_TEXTURE_CUBE_MAP_NV = $885A;
     GL_DOT_PRODUCT_PASS_THROUGH_NV = $885B;
     GL_DOT_PRODUCT_TEXTURE_1D_NV = $885C;
     GL_DOT_PRODUCT_AFFINE_DEPTH_REPLACE_NV = $885D;
     GL_HILO8_NV = $885E;
     GL_SIGNED_HILO8_NV = $885F;
     GL_FORCE_BLUE_TO_ONE_NV = $8860;
  { NV_register_combiners2  }
     GL_PER_STAGE_CONSTANTS_NV = $8535;
  { IBM_texture_mirrored_repeat  }
     GL_MIRRORED_REPEAT_IBM = $8370;
  { ARB_texture_env_dot3  }
     GL_DOT3_RGB_ARB = $86AE;
     GL_DOT3_RGBA_ARB = $86AF;
  { EXT_texture_env_dot3  }
     GL_DOT3_RGB_EXT = $8740;
     GL_DOT3_RGBA_EXT = $8741;
  { APPLE_transform_hint  }
     GL_TRANSFORM_HINT_APPLE = $85B1;
  { ARB_texture_border_clamp  }
     GL_CLAMP_TO_BORDER_ARB = $812D;
  { NV_texture_rectangle  }
     GL_TEXTURE_RECTANGLE_NV = $84F5;
     GL_TEXTURE_BINDING_RECTANGLE_NV = $84F6;
     GL_PROXY_TEXTURE_RECTANGLE_NV = $84F7;
     GL_MAX_RECTANGLE_TEXTURE_SIZE_NV = $84F8;
  { SGIX_shadow  }
     GL_TEXTURE_COMPARE_SGIX = $819A;
     GL_TEXTURE_COMPARE_OPERATOR_SGIX = $819B;
     GL_TEXTURE_LEQUAL_R_SGIX = $819C;
     GL_TEXTURE_GEQUAL_R_SGIX = $819D;
  { SGIX_depth_texture  }
     GL_DEPTH_COMPONENT16_SGIX = $81A5;
     GL_DEPTH_COMPONENT24_SGIX = $81A6;
     GL_DEPTH_COMPONENT32_SGIX = $81A7;
  { ARB_multisample  }
     GL_MULTISAMPLE_ARB = $809D;
     GL_SAMPLE_ALPHA_TO_COVERAGE_ARB = $809E;
     GL_SAMPLE_ALPHA_TO_ONE_ARB = $809F;
     GL_SAMPLE_COVERAGE_ARB = $80A0;
     GL_SAMPLE_BUFFERS_ARB = $80A8;
     GL_SAMPLES_ARB = $80A9;
     GL_SAMPLE_COVERAGE_VALUE_ARB = $80AA;
     GL_SAMPLE_COVERAGE_INVERT_ARB = $80AB;
     GL_MULTISAMPLE_BIT_ARB = $20000000;
  { NV_multisample_filter_hint  }
     GL_MULTISAMPLE_FILTER_HINT_NV = $8534;
  { NV_packed_depth_stencil  }
     GL_DEPTH_STENCIL_NV = $84F9;
     GL_UNSIGNED_INT_24_8_NV = $84FA;
  { EXT_draw_range_elements  }
     GL_MAX_ELEMENTS_VERTICES_EXT = $80E8;
     GL_MAX_ELEMENTS_INDICES_EXT = $80E9;
  { SGIS_generate_mipmap  }
     GL_GENERATE_MIPMAP_SGIS = $8191;
     GL_GENERATE_MIPMAP_HINT_SGIS = $8192;
  { NV_pixel_data_range  }
     GL_WRITE_PIXEL_DATA_RANGE_NV = $6001;
     GL_READ_PIXEL_DATA_RANGE_NV = $6002;
     GL_WRITE_PIXEL_DATA_RANGE_LENGTH_NV = $6003;
     GL_READ_PIXEL_DATA_RANGE_LENGTH_NV = $6004;
     GL_WRITE_PIXEL_DATA_RANGE_POINTER_NV = $6005;
     GL_READ_PIXEL_DATA_RANGE_POINTER_NV = $6006;
  { NV_packed_normal }
     GL_UNSIGNED_INT_S10_S11_S11_REV_NV = $886B;
 // NV_half_float
     GL_HALF_FLOAT_NV = $886C;
 // NV_copy_depth_to_color
     GL_DEPTH_STENCIL_TO_RGBA_NV = $886E;
     GL_DEPTH_STENCIL_TO_BGRA_NV = $886F;
 // HP_occlusion_test
     GL_OCCLUSION_TEST_HP = $8165;
     GL_OCCLUSION_TEST_RESULT_HP = $8166;
 // NV_occlusion_query
     GL_PIXEL_COUNTER_BITS_NV = $8864;
     GL_CURRENT_OCCLUSION_QUERY_ID_NV = $8865;
     GL_PIXEL_COUNT_NV = $8866;
     GL_PIXEL_COUNT_AVAILABLE_NV = $8867;
 // NV_point_sprite
     GL_POINT_SPRITE_NV = $8861;
     GL_COORD_REPLACE_NV = $8862;
     GL_POINT_SPRITE_R_MODE_NV = $8863;
 // 3DFX_tbuffer
     GL_TBUFFER_WRITE_MASK_3DFX = $86D8;
 // NV_depth_clamp
     GL_DEPTH_CLAMP_NV = $864F;
  {                                                            }

// -------------------------------------------------------
//   OpenGL procs and funcs
// -------------------------------------------------------

procedure glAccum(op: GLenum; value: Single); cdecl; external;
procedure glActiveTexture(texture: GLenum); cdecl; external;
procedure glActiveTextureARB(texture: GLenum); cdecl; external;
procedure glAddSwapHintRectWIN(x, y: GLint; width, height: GLsizei); cdecl; external;
procedure glAlphaFunc(func: GLenum; ref: GLclampf); cdecl; external;
function glAreProgramsResidentNV(n: GLsizei; const programs: PGLuint; residences: PGLboolean): GLboolean; cdecl; external;
function glAreTexturesResident(n: LongInt; var textures: LongWord; var residences: Boolean): Boolean; cdecl; external;
function glAreTexturesResidentEXT(n: LongInt; var textures: LongWord; var residences: Boolean): Boolean; cdecl; external;
procedure glArrayElement(i: LongInt); cdecl; external;
procedure glArrayElementEXT(i: LongInt); cdecl; external;
procedure glBegin(mode: GLenum); cdecl; external;
procedure glBeginOcclusionQueryNV(id: GLuint); cdecl; external;
procedure glBindProgramNV(target: GLenum; id: GLuint); cdecl; external;
procedure glBindTexture(target: GLenum; texture: LongWord); cdecl; external;
procedure glBindTextureEXT(target: GLenum; texture: LongWord); cdecl; external;
procedure glBitmap(width, height: LongInt; xorig, yorig, xmove, ymove: Single; var bitmap); cdecl; external;
procedure glBlendColor(red, green, blue, alpha: GLclampf); cdecl; external;
procedure glBlendColorEXT(red, green, blue, alpha: GLclampf); cdecl; external;
procedure glBlendEquation(mode: GLenum); cdecl; external;
procedure glBlendEquationEXT(mode: GLenum); cdecl; external;
procedure glBlendFunc(sfactor, dfactor: GLenum); cdecl; external;
procedure glCallList(list: LongWord); cdecl; external;
procedure glCallLists(n: LongInt; _Type: GLenum; var lists); cdecl; external;
procedure glClear(mask: GLbitfield); cdecl; external;
procedure glClearAccum(red, green, blue, alpha: Single); cdecl; external;
procedure glClearColor(red, green, blue, alpha: GLclampf); cdecl; external;
procedure glClearIndex(c: Single); cdecl; external;
procedure glClearDepth(depth: GLclampd); cdecl; external;
procedure glClearStencil(s: LongInt); cdecl; external;
procedure glClientActiveTexture(texture: GLenum); cdecl; external;
procedure glClientActiveTextureARB(texture: GLenum); cdecl; external;
procedure glClipPlane(plane: GLenum; var equation: Double); cdecl; external;
procedure glColor3b (red, green, blue: ShortInt); cdecl; external;
procedure glColor3bv (v: PShortInt); cdecl; external;
procedure glColor3d (red, green, blue: Double); cdecl; external;
procedure glColor3dv (v: PDouble); cdecl; external;
procedure glColor3f (red, green, blue: Single); cdecl; external;
procedure glColor3fv (v:PSingle); cdecl; external;
procedure glColor3i (red, green, blue: LongInt); cdecl; external;
procedure glColor3iv (v: PLongInt); cdecl; external;
procedure glColor3s (red, green, blue: SmallInt); cdecl; external;
procedure glColor3sv (v: PSmallInt); cdecl; external;
procedure glColor3ub(red, green, blue: Byte); cdecl; external;
procedure glColor3ubv(v: PByte); cdecl; external;
procedure glColor3ui(red, green, blue: LongWord); cdecl; external;
procedure glColor3uiv(v: PLongWord); cdecl; external;
procedure glColor3us(red, green, blue: Word); cdecl; external;
procedure glColor3usv(v: PWord); cdecl; external;
procedure glColor4b (red, green, blue, alpha: ShortInt); cdecl; external;
procedure glColor4bv (v: PShortInt); cdecl; external;
procedure glColor4d (red, green, blue, alpha: Double); cdecl; external;
procedure glColor4dv (v: PDouble); cdecl; external;
procedure glColor4f (red, green, blue, alpha: Single); cdecl; external;
procedure glColor4fv (v: PSingle); cdecl; external;
procedure glColor4i (red, green, blue, alpha: LongInt); cdecl; external;
procedure glColor4iv (v: PLongInt); cdecl; external;
procedure glColor4s (red, green, blue, alpha: SmallInt); cdecl; external;
procedure glColor4sv (v: PSmallInt); cdecl; external;
procedure glColor4ub(red, green, blue, alpha: Byte); cdecl; external;
procedure glColor4ubv(v: PByte); cdecl; external;
procedure glColor4ui(red, green, blue, alpha: LongWord); cdecl; external;
procedure glColor4uiv(v: PLongWord); cdecl; external;
procedure glColor4us(red, green, blue, alpha: Word); cdecl; external;
procedure glColor4usv(v: PWord); cdecl; external;
procedure glColorMask(red, green, blue, alpha: GLboolean); cdecl; external;
procedure glColorMaterial(face, mode: GLenum); cdecl; external;
procedure glColorPointer(size: LongInt; _Type: GLenum; stride: LongInt; var ptr); cdecl; external;
procedure glColorPointerEXT(size: LongInt; _Type: GLenum; stride, count: LongInt; var ptr); cdecl; external;
procedure glColorSubTable(target: GLenum; start, count: GLsizei; format, _type: GLenum; const data: PGLvoid); cdecl; external;
procedure glColorSubTableEXT(target: GLenum; start, count: LongInt; format, _Type: GLEnum; var data); cdecl; external;
procedure glColorTable(target, internalformat: GLenum; width: GLsizei; format, _type: GLenum; const table: PGLvoid); cdecl; external;
procedure glColorTableEXT(target, internalformat: GLenum; width: LongInt; format, _Type: GLenum; var table); cdecl; external;
procedure glColorTableParameterfv(target, pname: GLenum; const params: PGLfloat); cdecl; external;
procedure glColorTableParameteriv(target, pname: GLenum; const params: PGLint); cdecl; external;
procedure glCombinerInputNV(stage, portion, variable, input, mapping, componentUsage: GLenum); cdecl; external;
procedure glCombinerOutputNV(stage, portion, abOutput, cdOutput, sumOutput, scale, bias: GLenum; abDotProduct, cdDotProduct, muxSum: GLboolean); cdecl; external;
procedure glCombinerParameterfNV(pname: GLenum; param: GLfloat); cdecl; external;
procedure glCombinerParameterfvNV(pname: GLenum; const params: PGLfloat); cdecl; external;
procedure glCombinerParameteriNV(pname: GLenum; param: GLint); cdecl; external;
procedure glCombinerParameterivNV(pname: GLenum; const params: PGLint); cdecl; external;
procedure glCombinerStageParameterfvNV(stage, pname: GLenum; const params: PGLfloat); cdecl; external;
procedure glCompressedTexImage1D(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexImage1DARB(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexImage2D(target: GLenum; level: GLint; internalformat: GLenum; width, height: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexImage2DARB(target: GLenum; level: GLint; internalformat: GLenum; width, height: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexImage3D(target: GLenum; level: GLint; internalformat: GLenum; width, height, depth: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexImage3DARB(target: GLenum; level: GLint; internalformat: GLenum; width, height, depth: GLsizei; border: GLint; imageSize:  GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage1D(target: GLenum; level, xoffset: GLint; width: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage1DARB(target: GLenum; level, xoffset: GLint; width: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage2D(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage2DARB(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage3D(target: GLenum; level, xoffset, yoffset, zoffset: GLint; width, height, depth: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glCompressedTexSubImage3DARB(target: GLenum; level, xoffset, yoffset, zoffset: GLint; width, height, depth: GLsizei; format: GLenum; imageSize: GLsizei; const data: PGLvoid); cdecl; external;
procedure glConvolutionFilter1D(target, internalformat: GLenum; width: GLsizei; format, _type: GLenum; const image: PGLvoid); cdecl; external;
procedure glConvolutionFilter2D(target, internalformat: GLenum; width, height: GLsizei; format, _type: GLenum; const image: PGLvoid); cdecl; external;
procedure glConvolutionParameterf(target, pname: GLenum; params: GLfloat); cdecl; external;
procedure glConvolutionParameterfv(target, pname: GLenum; const params: PGLfloat); cdecl; external;
procedure glConvolutionParameteri(target, pname: GLenum; params: GLint); cdecl; external;
procedure glConvolutionParameteriv(target, pname: GLenum; const params: PGLint); cdecl; external;
procedure glCopyColorSubTable(target: GLenum; start: GLsizei; x, y: GLint; width: GLsizei); cdecl; external;
procedure glCopyColorTable(target, internalformat: GLenum; x, y: GLint; width: GLsizei); cdecl; external;
procedure glCopyConvolutionFilter1D(target, internalformat: GLenum; x, y: GLint; width:  GLsizei); cdecl; external;
procedure glCopyConvolutionFilter2D(target, internalformat: GLenum; x, y: GLint; width, height: GLsizei); cdecl; external;
procedure glCopyPixels(x, y, width, height: LongInt; _Type: GLenum); cdecl; external;
procedure glCopyTexImage1D(target: GLenum; level: LongInt; format: GLenum; x, y, width, border: LongInt); cdecl; external;
procedure glCopyTexImage2D(target: GLenum; level: LongInt; format: GLenum; x, y, width, height, border: LongInt); cdecl; external;
procedure glCopyTexSubImage1D(target: GLenum; level, xoffset, x, y, width: LongInt); cdecl; external;
procedure glCopyTexSubImage2D(target: GLenum; level, xoffset, yoffset, x, y, width, height: LongInt); cdecl; external;
procedure glCopyTexSubImage3D(target: GLenum; level: LongInt; xoffset, yoffset, zoffset, x, y, width, height: LongInt); cdecl; external;
procedure glCopyTexSubImage3DEXT(target: GLenum; level: LongInt; xoffset, yoffset, zoffset, x, y, width, height: LongInt); cdecl; external;
procedure glCullFace(mode: GLenum); cdecl; external;
procedure glDeleteFencesNV(n: GLsizei; const fences: PGLuint); cdecl; external;
procedure glDeleteLists(list: LongWord; range: LongInt); cdecl; external;
procedure glDeleteOcclusionQueriesNV(n: GLsizei; const ids: PGLuint); cdecl; external;
procedure glDeleteProgramsNV(n: GLsizei; const programs: PGLuint); cdecl; external;
procedure glDeleteTextures(n: LongInt; var textures: LongWord); cdecl; external;
procedure glDeleteTexturesEXT(n: LongInt; var textures: LongWord); cdecl; external;
procedure glDepthFunc(func: LongInt); cdecl; external;
procedure glDepthMask(flag: GLBoolean); cdecl; external;
procedure glDepthRange(near_val, far_val: GLclampd); cdecl; external;
procedure glDisable(cap: LongInt); cdecl; external;
procedure glDisableClientState(cap: GLenum); cdecl; external;
procedure glDrawArrays(mode: GLenum; first, count: LongInt); cdecl; external;
procedure glDrawArraysEXT(mode: GLEnum; first, count: LongInt); cdecl; external;
procedure glDrawBuffer(mode: GLenum); cdecl; external;
procedure glDrawElements(mode: GLenum; count: Integer; _Type: GLenum; var indices); cdecl; external;
procedure glDrawMeshNV(mode: GLenum; count: GLsizei; _type: GLenum; stride: GLsizei; const indicesTexCoord, indicesNormal, indicesVertex: PGLvoid); cdecl; external;
procedure glDrawPixels(width, height: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glDrawRangeElements(mode: GLenum; _Start, _End: LongWord; count: LongInt; _Type: GLenum; var indices); cdecl; external;
procedure glDrawRangeElementsEXT(mode: GLenum; start, _end: GLuint; count: GLsizei; _type: GLenum; const indices: PGLvoid); cdecl; external;
procedure glEdgeFlag(flag: GLBoolean); cdecl; external;
procedure glEdgeFlagPointer(stride: LongInt; var ptr); cdecl; external;
procedure glEdgeFlagPointerEXT(stride, count: LongInt; var ptr: Boolean); cdecl; external;
procedure glEdgeFlagv(var flag: GLBoolean); cdecl; external;
procedure glEnable(cap: LongInt); cdecl; external;
procedure glEnableClientState(cap: GLenum); cdecl; external;
procedure glEnd; cdecl; external;
procedure glEndList; cdecl; external;
procedure glEndOcclusionQueryNV; cdecl; external;
procedure glEvalCoord1d(u: Double); cdecl; external;
procedure glEvalCoord1dv(var u: Double); cdecl; external;
procedure glEvalCoord1f(u: Single); cdecl; external;
procedure glEvalCoord1fv(var u: Single); cdecl; external;
procedure glEvalCoord2d(u, v: Double); cdecl; external;
procedure glEvalCoord2dv(var u, v: Double); cdecl; external;
procedure glEvalCoord2f(u, v: Single); cdecl; external;
procedure glEvalCoord2fv(var u, v: Single); cdecl; external;
procedure glEvalMapsNV(target, mode: GLenum); cdecl; external;
procedure glEvalMesh1(mode: GLenum; i1, i2: LongInt); cdecl; external;
procedure glEvalMesh2(mode: GLenum; i1, i2, j1, j2: LongInt); cdecl; external;
procedure glEvalPoint1(i: LongInt); cdecl; external;
procedure glEvalPoint2(i, j: LongInt); cdecl; external;
procedure glExecuteProgramNV(target: GLenum; id: GLuint; const params: PGLfloat); cdecl; external;
procedure glFeedbackBuffer(size: LongInt; _Type: GLenum; var buffer: Single); cdecl; external;
procedure glFinalCombinerInputNV(variable, input, mapping, componentUsage: GLenum); cdecl; external;
procedure glFinish; cdecl; external;
procedure glFinishFenceNV(fence: GLuint); cdecl; external;
procedure glFlush; cdecl; external;
procedure glFlushPixelDataRangeNV(target: GLenum); cdecl; external;
procedure glFlushVertexArrayRangeNV; cdecl; external;
function glFlushHold: PGLvoid; cdecl; external;
procedure glFogCoordPointerEXT(_type: GLenum; stride: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glFogCoorddEXT(fog: GLdouble); cdecl; external;
procedure glFogCoorddvEXT(const fog: PGLdouble); cdecl; external;
procedure glFogCoordfEXT(fog: GLfloat); cdecl; external;
procedure glFogCoordfvEXT(const fog: PGLfloat); cdecl; external;
procedure glFogf(pname: GLenum; param: Single); cdecl; external;
procedure glFogfv(pname: GLenum; params : PSingle); cdecl; external;
procedure glFogi(pname: GLenum; param: LongInt); cdecl; external;
procedure glFogiv(pname: GLenum; params : PLongInt); cdecl; external;
procedure glFrontFace(mode: GLenum); cdecl; external;
procedure glFrustum(left, right, bottom, top, near_val, far_val: Double); cdecl; external;
procedure glGenFencesNV(n: GLsizei; fences: PGLuint); cdecl; external;
procedure glGenOcclusionQueriesNV(n: GLsizei; ids: PGLuint); cdecl; external;
function glGenLists(range: LongInt): LongWord; cdecl; external;
procedure glGenProgramsNV(n: GLsizei; programs: PGLuint); cdecl; external;
procedure glGenTextures(n: LongInt; var textures: LongWord); cdecl; external;
procedure glGenTexturesEXT(n: LongInt; var textures: LongWord); cdecl; external;
procedure glGetBooleanv(pname: GLenum; params : PGLBoolean); cdecl; external;
procedure glGetClipPlane(plane: GLenum; var equation: Double); cdecl; external;
procedure glGetColorTable(target, format, _type: GLenum; table: PGLvoid); cdecl; external;
procedure glGetColorTableEXT(target, format, _Type: GLenum; var table); cdecl; external;
procedure glGetColorTableParameterfv(target, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetColorTableParameterfvEXT(target, pname: GLenum; var params: Single); cdecl; external;
procedure glGetColorTableParameteriv(target, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetColorTableParameterivEXT(target, pname: GLenum; var params: LongInt); cdecl; external;
procedure glGetCombinerInputParameterfvNV(stage, portion, variable, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetCombinerInputParameterivNV(stage, portion, variable, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetCombinerOutputParameterfvNV(stage, portion, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetCombinerOutputParameterivNV(stage, portion, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetCombinerStageParameterfvNV(stage, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetCompressedTexImage(target: GLenum; lod: GLint; img: PGLvoid); cdecl; external;
procedure glGetCompressedTexImageARB(target: GLenum; lod: GLint; img: PGLvoid); cdecl; external;
procedure glGetConvolutionFilter(target, format, _type: GLenum; image: PGLvoid); cdecl; external;
procedure glGetConvolutionParameterfv(target, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetConvolutionParameteriv(target, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetDoublev(pname: GLenum; params : PDouble); cdecl; external;
function glGetError: GLenum; cdecl; external;
procedure glGetFenceivNV(fence: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glGetFinalCombinerInputParameterfvNV(variable, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetFinalCombinerInputParameterivNV(variable, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetFloatv(pname: GLenum; params : PSingle); cdecl; external;
procedure glGetHistogram(target: GLenum; reset: GLboolean; format, _type: GLenum; values: PGLvoid); cdecl; external;
procedure glGetHistogramParameterfv(target, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetHistogramParameteriv(target, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetIntegerv(pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetLightfv(light, pname: GLenum; params : PSingle); cdecl; external;
procedure glGetLightiv(light, pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetMapAttribParameterfvNV(target: GLenum; index: GLuint; pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetMapAttribParameterivNV(target: GLenum; index: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glGetMapControlPointsNV(target: GLenum; index: GLuint; _type: GLenum; ustride, vstride: GLsizei; _packed: GLboolean; points: PGLvoid); cdecl; external;
procedure glGetMapParameterfvNV(target, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetMapParameterivNV(target, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetMapdv(target, query: GLenum; var v: Double); cdecl; external;
procedure glGetMapfv(target, query: GLenum; var v: Single); cdecl; external;
procedure glGetMapiv(target, query: GLenum; var v: LongInt); cdecl; external;
procedure glGetMaterialfv(face, pname: GLenum; params : PSingle); cdecl; external;
procedure glGetMaterialiv(face, pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetMinmax(target: GLenum; reset: GLboolean; format, _type: GLenum; values: PGLvoid); cdecl; external;
procedure glGetMinmaxParameterfv(target, pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetMinmaxParameteriv(target, pname: GLenum; params: PGLint); cdecl; external;
procedure glGetOcclusionQueryivNV(id: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glGetOcclusionQueryuivNV(id: GLuint; pname: GLenum; params: PGLuint); cdecl; external;
procedure glGetPixelMapfv(map: GLenum; var values: Single); cdecl; external;
procedure glGetPixelMapuiv(map: GLenum; var values: LongWord); cdecl; external;
procedure glGetPixelMapusv(map: GLenum; var values: Word); cdecl; external;
procedure glGetPointerv(pname: GLenum; var params: Pointer); cdecl; external;
procedure glGetPointervEXT(pname: GLenum; var params: Pointer); cdecl; external;
procedure glGetPolygonStipple(var mask: Byte); cdecl; external;
procedure glGetProgramLocalParameterdvNV(target: GLenum; len: GLsizei; const name: PGLubyte; params: PGLdouble); cdecl; external;
procedure glGetProgramLocalParameterfvNV(target: GLenum; len: GLsizei; const name: PGLubyte; params: PGLfloat); cdecl; external;
procedure glGetProgramParameterSigneddvNV(target: GLenum; index: GLint; pname: GLenum; params: PGLdouble); cdecl; external;
procedure glGetProgramParameterSignedfvNV(target: GLenum; index: GLint; pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetProgramParameterdvNV(target: GLenum; index: GLuint; pname: GLenum; params: PGLdouble); cdecl; external;
procedure glGetProgramParameterfvNV(target: GLenum; index: GLuint; pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetProgramStringNV(id: GLuint; pname: GLenum; _program: PGLubyte); cdecl; external;
procedure glGetProgramivNV(id: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glGetSeparableFilter(target, format, _type: GLenum; row, column, span: PGLvoid); cdecl; external;
function glGetString(name: GLenum): PChar; cdecl; external;
procedure glGetTexEnvfv(target, pname: GLenum; params : PSingle); cdecl; external;
procedure glGetTexEnviv(target, pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetTexGendv(cord, pname: GLenum; params : PDouble); cdecl; external;
procedure glGetTexGenfv(cord, pname: GLenum; params : PSingle); cdecl; external;
procedure glGetTexGeniv(cord, pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetTexImage(target: GLenum; level: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glGetTexParameterfv(target, pname: GLenum; params : PSingle); cdecl; external;
procedure glGetTexParameteriv(target, pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetTexLevelParameterfv(target: GLenum; level: LongInt; pname: GLenum; params : PSingle); cdecl; external;
procedure glGetTexLevelParameteriv(target: GLenum; level: LongInt; pname: GLenum; params : PLongInt); cdecl; external;
procedure glGetTrackMatrixivNV(target: GLenum; address: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glGetVertexAttribPointervNV(index: GLuint; pname: GLenum; var _pointer: pointer); cdecl; external;
procedure glGetVertexAttribdvNV(index: GLuint; pname: GLenum; params: PGLdouble); cdecl; external;
procedure glGetVertexAttribfvNV(index: GLuint; pname: GLenum; params: PGLfloat); cdecl; external;
procedure glGetVertexAttribivNV(index: GLuint; pname: GLenum; params: PGLint); cdecl; external;
procedure glHint(target, mode: GLenum); cdecl; external;
procedure glHistogram(target: GLenum; width: GLsizei; internalformat: GLenum; sink: GLboolean); cdecl; external;
procedure glIndexMask(mask: LongWord); cdecl; external;
procedure glIndexPointer(_Type: GLenum; stride: LongInt; var ptr); cdecl; external;
procedure glIndexPointerEXT(_Type: GLenum; stride, count: LongInt; var ptr); cdecl; external;
procedure glIndexd(c: Double); cdecl; external;
procedure glIndexdv(var c: Double); cdecl; external;
procedure glIndexf(c: Single); cdecl; external;
procedure glIndexfv(var c: Single); cdecl; external;
procedure glIndexi(c: LongInt); cdecl; external;
procedure glIndexiv(var c: LongInt); cdecl; external;
procedure glIndexs(c: SmallInt); cdecl; external;
procedure glIndexsv(var c: SmallInt); cdecl; external;
procedure glIndexub(c: Byte); cdecl; external;
procedure glIndexubv(var c: Byte); cdecl; external;
procedure glInitNames; cdecl; external;
procedure glInterleavedArrays(format: GLenum; stride: LongInt; var pointer); cdecl; external;
function glIsEnabled(cap: GLenum): GLBoolean; cdecl; external;
function glIsFenceNV(fence: GLuint): GLBoolean; cdecl; external;
function glIsList(list: LongWord): GLBoolean; cdecl; external;
function glIsOcclusionQueryNV(id: GLuint): GLBoolean; cdecl; external;
function glIsProgramNV(id: GLuint): GLBoolean; cdecl; external;
function glIsTexture(texture: LongWord): Boolean; cdecl; external;
function glIsTextureEXT(texture: LongWord): Boolean; cdecl; external;
procedure glLightModelf(pname: GLenum; param: Single); cdecl; external;
procedure glLightModelfv(pname: GLenum; params : PSingle); cdecl; external;
procedure glLightModeli(pname: GLenum; param: LongInt); cdecl; external;
procedure glLightModeliv(pname: GLenum; params : PLongInt); cdecl; external;
procedure glLightf(light, pname: GLenum; param: Single); cdecl; external;
procedure glLightfv(light, pname: GLenum; params : PSingle); cdecl; external;
procedure glLighti(light, pname: GLenum; param: LongInt); cdecl; external;
procedure glLightiv(light, pname: GLenum; params : PLongInt); cdecl; external;
procedure glLineStipple(factor: LongInt; pattern: Word); cdecl; external;
procedure glLineWidth(width: Single); cdecl; external;
procedure glListBase(base: LongWord); cdecl; external;
procedure glLoadIdentity; cdecl; external;
procedure glLoadMatrixd(m: PGLDouble); cdecl; external;
procedure glLoadMatrixf(m: PGLFloat); cdecl; external;
procedure glLoadName(name: LongWord); cdecl; external;
procedure glLoadProgramNV(target: GLenum; id: GLuint; len: GLsizei; const _program: PGLubyte); cdecl; external;
procedure glLoadTransposeMatrixd(const m: PGLdouble); cdecl; external;
procedure glLoadTransposeMatrixdARB(const m: PGLdouble); cdecl; external;
procedure glLoadTransposeMatrixf(const m: PGLfloat); cdecl; external;
procedure glLoadTransposeMatrixfARB(const m: PGLfloat); cdecl; external;
procedure glLockArraysEXT(first: GLint; count: GLsizei); cdecl; external;
procedure glLogicOp(opcode: GLenum); cdecl; external;
procedure glMap1d(target: GLenum; u1, u2: Double; stride, order: LongInt; var points: Double); cdecl; external;
procedure glMap1f(target: GLenum; u1, u2: Single; stride, order: LongInt; var points: Single); cdecl; external;
procedure glMap2d(target: GLenum; u1, u2: Double; ustride, uorder: LongInt; v1, v2: Double; vstride, vorder: LongInt; var points: Double); cdecl; external;
procedure glMap2f(target: GLenum; u1, u2: Single; ustride, uorder: LongInt; v1, v2: Single; vstride, vorder: LongInt; var points: Single); cdecl; external;
procedure glMapControlPointsNV(target: GLenum; index: GLuint; _type: GLenum; ustride, vstride: GLsizei; uorder, vorder: GLint; _packed: GLboolean; const points: PGLvoid); cdecl; external;
procedure glMapGrid1d(un: LongInt; u1, u2: Double); cdecl; external;
procedure glMapGrid1f(un: LongInt; u1, u2: Single); cdecl; external;
procedure glMapGrid2d(un: LongInt; u1, u2: Double; vn: LongInt; v1, v2: Double); cdecl; external;
procedure glMapGrid2f(un: LongInt; u1, u2: Single; vn: LongInt; v1, v2: Single); cdecl; external;
procedure glMapParameterfvNV(target, pname: GLenum; const params: PGLfloat); cdecl; external;
procedure glMapParameterivNV(target, pname: GLenum; const params: PGLint); cdecl; external;
procedure glMaterialf(face, pname: GLenum; param: Single); cdecl; external;
procedure glMaterialfv(face, pname: GLenum; params : PSingle); cdecl; external;
procedure glMateriali(face, pname: GLenum; param: LongInt); cdecl; external;
procedure glMaterialiv(face, pname: GLenum; params : PLongInt); cdecl; external;
procedure glMatrixMode(mode: GLenum); cdecl; external;
procedure glMinmax(target, internalformat: GLenum; sink: GLboolean); cdecl; external;
procedure glMultMatrixd(m: PGLDouble); cdecl; external;
procedure glMultMatrixf(m: PGLFloat); cdecl; external;
procedure glMultTransposeMatrixd(const m: PGLdouble); cdecl; external;
procedure glMultTransposeMatrixdARB(const m: PGLdouble); cdecl; external;
procedure glMultTransposeMatrixf(const m: PGLfloat); cdecl; external;
procedure glMultTransposeMatrixfARB(const m: PGLfloat); cdecl; external;
procedure glMultiDrawArraysEXT(mode: GLenum; const first: PGLint; const count: PGLsizei; primcount: GLsizei); cdecl; external;
procedure glMultiDrawElementsEXT(mode: GLenum; const count: PGLsizei; _type: GLenum; const indices: PGLVoid; primcount: GLsizei); cdecl; external;
procedure glMultiTexCoord1d(target: GLenum; s: GLdouble); cdecl; external;
procedure glMultiTexCoord1dARB(target: GLenum; s: GLdouble); cdecl; external;
procedure glMultiTexCoord1dSGIS(target: GLenum; s: Double); cdecl; external;
procedure glMultiTexCoord1dv(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord1dvARB(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord1dvSGIS(target: GLenum; var v: Double); cdecl; external;
procedure glMultiTexCoord1f(target: GLenum; s: GLfloat); cdecl; external;
procedure glMultiTexCoord1fARB(target: GLenum; s: GLfloat); cdecl; external;
procedure glMultiTexCoord1fSGIS(target: GLenum; s: Single); cdecl; external;
procedure glMultiTexCoord1fv(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord1fvARB(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord1fvSGIS(target: GLenum; var v: Single); cdecl; external;
procedure glMultiTexCoord1i(target: GLenum; s: GLint); cdecl; external;
procedure glMultiTexCoord1iARB(target: GLenum; s: GLint); cdecl; external;
procedure glMultiTexCoord1iSGIS(target: GLenum; s: LongInt); cdecl; external;
procedure glMultiTexCoord1iv(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord1ivARB(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord1ivSGIS(target: GLenum; var v: LongInt); cdecl; external;
procedure glMultiTexCoord1s(target: GLenum; s: GLshort); cdecl; external;
procedure glMultiTexCoord1sARB(target: GLenum; s: GLshort); cdecl; external;
procedure glMultiTexCoord1sSGIS(target: GLenum; s: ShortInt); cdecl; external;
procedure glMultiTexCoord1sv(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord1svARB(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord1svSGIS(target: GLenum; var v: ShortInt); cdecl; external;
procedure glMultiTexCoord2d(target: GLenum; s, t: GLdouble); cdecl; external;
procedure glMultiTexCoord2dARB(target: GLenum; s, t: GLdouble); cdecl; external;
procedure glMultiTexCoord2dSGIS(target: GLenum; s, t: Double); cdecl; external;
procedure glMultiTexCoord2dv(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord2dvARB(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord2dvSGIS(target: GLenum; var v: Double); cdecl; external;
procedure glMultiTexCoord2f(target: GLenum; s, t: GLfloat); cdecl; external;
procedure glMultiTexCoord2fARB(target: GLenum; s, t: GLfloat); cdecl; external;
procedure glMultiTexCoord2fSGIS(target: GLenum; s, t: Single); cdecl; external;
procedure glMultiTexCoord2fv(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord2fvARB(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord2fvSGIS(target: GLenum; var v: Single); cdecl; external;
procedure glMultiTexCoord2i(target: GLenum; s, t: GLint); cdecl; external;
procedure glMultiTexCoord2iARB(target: GLenum; s, t: GLint); cdecl; external;
procedure glMultiTexCoord2iSGIS(target: GLenum; s, t: LongInt); cdecl; external;
procedure glMultiTexCoord2iv(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord2ivARB(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord2ivSGIS(target: GLenum; var v: LongInt); cdecl; external;
procedure glMultiTexCoord2s(target: GLenum; s, t: GLshort); cdecl; external;
procedure glMultiTexCoord2sARB(target: GLenum; s, t: GLshort); cdecl; external;
procedure glMultiTexCoord2sSGIS(target: GLenum; s, t: ShortInt); cdecl; external;
procedure glMultiTexCoord2sv(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord2svARB(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord2svSGIS(target: GLenum; var v: ShortInt); cdecl; external;
procedure glMultiTexCoord3d(target: GLenum; s, t, r: GLdouble); cdecl; external;
procedure glMultiTexCoord3dARB(target: GLenum; s, t, r: GLdouble); cdecl; external;
procedure glMultiTexCoord3dSGIS(target: GLenum; s, t, r: Double); cdecl; external;
procedure glMultiTexCoord3dv(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord3dvARB(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord3dvSGIS(target: GLenum; var v: Double); cdecl; external;
procedure glMultiTexCoord3f(target: GLenum; s, t, r: GLfloat); cdecl; external;
procedure glMultiTexCoord3fARB(target: GLenum; s, t, r: GLfloat); cdecl; external;
procedure glMultiTexCoord3fSGIS(target: GLenum; s, t, r: Single); cdecl; external;
procedure glMultiTexCoord3fv(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord3fvARB(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord3fvSGIS(target: GLenum; var v: Single); cdecl; external;
procedure glMultiTexCoord3i(target: GLenum; s, t, r:  GLint); cdecl; external;
procedure glMultiTexCoord3iARB(target: GLenum; s, t, r:  GLint); cdecl; external;
procedure glMultiTexCoord3iSGIS(target: GLenum; s, t, r: LongInt); cdecl; external;
procedure glMultiTexCoord3iv(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord3ivARB(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord3ivSGIS(target: GLenum; var v: LongInt); cdecl; external;
procedure glMultiTexCoord3s(target: GLenum; s, t, r: GLshort); cdecl; external;
procedure glMultiTexCoord3sARB(target: GLenum; s, t, r: GLshort); cdecl; external;
procedure glMultiTexCoord3sSGIS(target: GLenum; s, t, r: ShortInt); cdecl; external;
procedure glMultiTexCoord3sv(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord3svARB(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord3svSGIS(target: GLenum; var v: ShortInt); cdecl; external;
procedure glMultiTexCoord4d(target: GLenum; s, t, r, q: GLdouble); cdecl; external;
procedure glMultiTexCoord4dARB(target: GLenum; s, t, r, q: GLdouble); cdecl; external;
procedure glMultiTexCoord4dSGIS(target: GLenum; s, t, r, q: Double); cdecl; external;
procedure glMultiTexCoord4dv(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord4dvARB(target: GLenum; const v: PGLdouble); cdecl; external;
procedure glMultiTexCoord4dvSGIS(target: GLenum; var v: Double); cdecl; external;
procedure glMultiTexCoord4f(target: GLenum; s, t, r, q: GLfloat); cdecl; external;
procedure glMultiTexCoord4fARB(target: GLenum; s, t, r, q: GLfloat); cdecl; external;
procedure glMultiTexCoord4fSGIS(target: GLenum; s, t, r, q: Single); cdecl; external;
procedure glMultiTexCoord4fv(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord4fvARB(target: GLenum; const v: PGLfloat); cdecl; external;
procedure glMultiTexCoord4fvSGIS(target: GLenum; var v: Single); cdecl; external;
procedure glMultiTexCoord4i(target: GLenum; s, t, r, q: GLint); cdecl; external;
procedure glMultiTexCoord4iARB(target: GLenum; s, t, r, q: GLint); cdecl; external;
procedure glMultiTexCoord4iSGIS(target: GLenum; s, t, r, q: LongInt); cdecl; external;
procedure glMultiTexCoord4iv(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord4ivARB(target: GLenum; const v: PGLint); cdecl; external;
procedure glMultiTexCoord4ivSGIS(target: GLenum; var v: LongInt); cdecl; external;
procedure glMultiTexCoord4s(target: GLenum; s, t, r, q: GLshort); cdecl; external;
procedure glMultiTexCoord4sARB(target: GLenum; s, t, r, q: GLshort); cdecl; external;
procedure glMultiTexCoord4sSGIS(target: GLenum; s, t, r, q: ShortInt); cdecl; external;
procedure glMultiTexCoord4sv(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord4svARB(target: GLenum; const v: PGLshort); cdecl; external;
procedure glMultiTexCoord4svSGIS(target: GLenum; var v: ShortInt); cdecl; external;
procedure glMultiTexCoordPointerSGIS(target: GLenum; size: LongInt; _Type: GLEnum; stride: LongInt; var _Pointer); cdecl; external;
procedure glNewList(list: LongWord; mode: GLenum); cdecl; external;
procedure glNormal3b(nx, ny, nz: Byte); cdecl; external;
procedure glNormal3bv(var v: ShortInt); cdecl; external;
procedure glNormal3d(nx, ny, nz: Double); cdecl; external;
procedure glNormal3dv(var v: Double); cdecl; external;
procedure glNormal3f(nx, ny, nz: Single); cdecl; external;
procedure glNormal3fv(var v: Single); cdecl; external;
procedure glNormal3i(nx, ny, nz: LongInt); cdecl; external;
procedure glNormal3iv(var v: LongInt); cdecl; external;
procedure glNormal3s(nx, ny, nz: SmallInt); cdecl; external;
procedure glNormal3sv(var v: SmallInt); cdecl; external;
procedure glNormalPointer(_Type: GLenum; stride: LongInt; var ptr); cdecl; external;
procedure glNormalPointerEXT(_Type: GLenum; stride, count: LongInt; var ptr); cdecl; external;
procedure glOrtho(left, right, bottom, top, near_val, far_val: Double); cdecl; external;
procedure glPassThrough(token: Single); cdecl; external;
procedure glPixelDataRangeNV(target: GLenum; size: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glPixelMapfv(map: GLenum; mapsize: LongInt; var values: Single); cdecl; external;
procedure glPixelMapuiv(map: GLenum; mapsize: LongInt; var values: LongWord); cdecl; external;
procedure glPixelMapusv(map: GLenum; mapsize: LongInt; var values: Word); cdecl; external;
procedure glPixelStoref(pname: GLenum; param: Single); cdecl; external;
procedure glPixelStorei(pname: GLenum; param: LongInt); cdecl; external;
procedure glPixelTransferf(pname: GLenum; param: Single); cdecl; external;
procedure glPixelTransferi(pname: GLenum; param: LongInt); cdecl; external;
procedure glPixelZoom(xfactor, yfactor: Single); cdecl; external;
procedure glPointParameteriNV(pname: GLenum; param: GLint); cdecl; external;
procedure glPointParameterivNV(pname: GLenum; const params: PGLint); cdecl; external;
procedure glPointParameterfEXT(pname: GLenum; param: Single); cdecl; external;
procedure glPointParameterfvEXT(pname: GLenum; var params: Single); cdecl; external;
procedure glPointSize(size: Single); cdecl; external;
procedure glPolygonMode(face, mode: GLenum); cdecl; external;
procedure glPolygonOffset(factor, units: Single); cdecl; external;
procedure glPolygonStipple(var mask: Byte); cdecl; external;
procedure glPopAttrib; cdecl; external;
procedure glPopClientAttrib; cdecl; external;
procedure glPopMatrix; cdecl; external;
procedure glPopName; cdecl; external;
procedure glPrioritizeTextures(n: LongInt; var textures: LongWord; var priorities: GLclampf); cdecl; external;
procedure glPrioritizeTexturesEXT(n: LongInt; var textures: LongWord; var priorities: GLClampf); cdecl; external;
procedure glProgramLocalParameter4dNV(target: GLenum; len: GLsizei; const name: PGLubyte; x, y, z, w: GLdouble); cdecl; external;
procedure glProgramLocalParameter4dvNV(target: GLenum; len: GLsizei; const name: PGLubyte; const v: PGLdouble); cdecl; external;
procedure glProgramLocalParameter4fNV(target: GLenum; len: GLsizei; const name: PGLubyte; x, y, z, w: GLfloat); cdecl; external;
procedure glProgramLocalParameter4fvNV(target: GLenum; len: GLsizei; const name: PGLubyte; const v: PGLfloat); cdecl; external;
procedure glProgramParameter4dNV(target: GLenum; index: GLuint; x, y, z, w: GLdouble); cdecl; external;
procedure glProgramParameter4dvNV(target: GLenum; index: GLuint; const v: PGLdouble); cdecl; external;
procedure glProgramParameter4fNV(target: GLenum; index: GLuint; x, y, z, w: GLfloat); cdecl; external;
procedure glProgramParameter4fvNV(target: GLenum; index: GLuint; const v: PGLfloat); cdecl; external;
procedure glProgramParameterSigned4dNV(target: GLenum; index: GLint; x, y, z, w: GLdouble); cdecl; external;
procedure glProgramParameterSigned4dvNV(target: GLenum; index: GLint; const v: PGLdouble); cdecl; external;
procedure glProgramParameterSigned4fNV(target: GLenum; index: GLint; x, y, z, w: GLfloat); cdecl; external;
procedure glProgramParameterSigned4fvNV(target: GLenum; index: GLint; const v: PGLfloat); cdecl; external;
procedure glProgramParameters4dvNV(target: GLenum; index: GLuint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glProgramParameters4fvNV(target: GLenum; index: GLuint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glProgramParametersSigned4dvNV(target: GLenum; index: GLint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glProgramParametersSigned4fvNV(target: GLenum; index: GLint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glPushAttrib(mask: GLbitfield); cdecl; external;
procedure glPushClientAttrib(mask: GLbitfield); cdecl; external;
procedure glPushMatrix; cdecl; external;
procedure glPushName(name: LongWord); cdecl; external;
procedure glRasterPos2d(x, y: Double); cdecl; external;
procedure glRasterPos2dv(var v: Double); cdecl; external;
procedure glRasterPos2f(x, y: Single); cdecl; external;
procedure glRasterPos2fv(var v: Single); cdecl; external;
procedure glRasterPos2i(x, y: LongInt); cdecl; external;
procedure glRasterPos2iv(var v: LongInt); cdecl; external;
procedure glRasterPos2s(x, y: SmallInt); cdecl; external;
procedure glRasterPos2sv(var v: SmallInt); cdecl; external;
procedure glRasterPos3d(x, y, z: Double); cdecl; external;
procedure glRasterPos3dv(var v: Double); cdecl; external;
procedure glRasterPos3f(x, y, z: Single); cdecl; external;
procedure glRasterPos3fv(var v: Single); cdecl; external;
procedure glRasterPos3i(x, y, z: LongInt); cdecl; external;
procedure glRasterPos3iv(var v: LongInt); cdecl; external;
procedure glRasterPos3s(x, y, z: SmallInt); cdecl; external;
procedure glRasterPos3sv(var v: SmallInt); cdecl; external;
procedure glRasterPos4d(x, y, z, w: Double); cdecl; external;
procedure glRasterPos4dv(var v: Double); cdecl; external;
procedure glRasterPos4f(x, y, z, w: Single); cdecl; external;
procedure glRasterPos4fv(var v: Single); cdecl; external;
procedure glRasterPos4i(x, y, z, w: LongInt); cdecl; external;
procedure glRasterPos4iv(var v: LongInt); cdecl; external;
procedure glRasterPos4s(x, y, z, w: SmallInt); cdecl; external;
procedure glRasterPos4sv(var v: SmallInt); cdecl; external;
procedure glReadBuffer(mode: GLenum); cdecl; external;
procedure glReadPixels(x, y, width, height: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glRectd(x1, y1, x2, y2: Double); cdecl; external;
procedure glRectf(x1, y1, x2, y2: Single); cdecl; external;
procedure glRecti(x1, y1, x2, y2: LongInt); cdecl; external;
procedure glRects(x1, y1, x2, y2: SmallInt); cdecl; external;
procedure glRectdv(var v1, v2: Double); cdecl; external;
procedure glRectfv(var v1, v2: Single); cdecl; external;
procedure glRectiv(var v1, v2: LongInt); cdecl; external;
procedure glRectsv(var v1, v2: SmallInt); cdecl; external;
function glReleaseFlushHold(const id: PGLvoid): GLenum; cdecl; external;
function glRenderMode(mode: GLenum): LongInt; cdecl; external;
procedure glRequestResidentProgramsNV(n: GLsizei; const programs: PGLuint); cdecl; external;
procedure glResetHistogram(target: GLenum); cdecl; external;
procedure glResetMinmax(target: GLenum); cdecl; external;
procedure glRotated(angle, x, y, z: Double); cdecl; external;
procedure glRotatef(angle, x, y, z: Single); cdecl; external;
procedure glSampleCoverage(value: GLclampf; invert: GLboolean); cdecl; external;
procedure glSampleCoverageARB(value: GLclampf; invert: GLboolean); cdecl; external;
procedure glScaled(x, y, z: Double); cdecl; external;
procedure glScalef(x, y, z: Single); cdecl; external;
procedure glScissor(x, y, width, height: LongInt); cdecl; external;
procedure glSecondaryColor3bEXT(red, green, blue: GLbyte); cdecl; external;
procedure glSecondaryColor3bvEXT(const v: PGLbyte); cdecl; external;
procedure glSecondaryColor3dEXT(red, green, blue: GLdouble); cdecl; external;
procedure glSecondaryColor3dvEXT(const v: PGLdouble); cdecl; external;
procedure glSecondaryColor3fEXT(red, green, blue: GLfloat); cdecl; external;
procedure glSecondaryColor3fvEXT(const v: PGLfloat); cdecl; external;
procedure glSecondaryColor3iEXT(red, green, blue: GLint); cdecl; external;
procedure glSecondaryColor3ivEXT(const v: PGLint); cdecl; external;
procedure glSecondaryColor3sEXT(red, green, blue: GLshort); cdecl; external;
procedure glSecondaryColor3svEXT(const v: PGLshort); cdecl; external;
procedure glSecondaryColor3ubEXT(red, green, blue: GLubyte); cdecl; external;
procedure glSecondaryColor3ubvEXT(const v: PGLubyte); cdecl; external;
procedure glSecondaryColor3uiEXT(red, green, blue: GLuint); cdecl; external;
procedure glSecondaryColor3uivEXT(const v: PGLuint); cdecl; external;
procedure glSecondaryColor3usEXT(red, green, blue: GLushort); cdecl; external;
procedure glSecondaryColor3usvEXT(const v: PGLushort); cdecl; external;
procedure glSecondaryColorPointerEXT(size: GLint; _type: GLenum; stride: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glSelectBuffer(size: LongInt; var buffer: LongWord); cdecl; external;
procedure glSelectTextureSGIS(target: GLenum); cdecl; external;
procedure glSelectTextureCoordSetSGIS(target: GLenum); cdecl; external;
procedure glSeparableFilter2D(target, internalformat: GLenum; width, height: GLsizei; format, _type: GLenum; const row, column: PGLvoid); cdecl; external;
procedure glSetFenceNV(fence: GLuint; condition: GLenum); cdecl; external;
procedure glSetWindowStereoModeNV(displayMode: GLboolean); cdecl; external;
procedure glShadeModel(mode: GLenum); cdecl; external;
procedure glStencilFunc(func: GLenum; ref: LongInt; mask: LongWord); cdecl; external;
procedure glStencilMask(mask: LongWord); cdecl; external;
procedure glStencilOp(fail, zfail, zpass: GLenum); cdecl; external;
procedure glTbufferMask3DFX(mask :GLuint); cdecl; external;
function glTestFenceNV(fence: GLuint): GLboolean; cdecl; external;
procedure glTexCoord1d(s: Double); cdecl; external;
procedure glTexCoord1dv(var v: Double); cdecl; external;
procedure glTexCoord1f(s: Single); cdecl; external;
procedure glTexCoord1fv(var v: Single); cdecl; external;
procedure glTexCoord1i(s: LongInt); cdecl; external;
procedure glTexCoord1iv(var v: LongInt); cdecl; external;
procedure glTexCoord1s(s: SmallInt); cdecl; external;
procedure glTexCoord1sv(var v: SmallInt); cdecl; external;
procedure glTexCoord2d(s, t: Double); cdecl; external;
procedure glTexCoord2dv(var v: Double); cdecl; external;
procedure glTexCoord2f(s, t: Single); cdecl; external;
procedure glTexCoord2fv(var v: Single); cdecl; external;
procedure glTexCoord2i(s, t: LongInt); cdecl; external;
procedure glTexCoord2iv(var v: LongInt); cdecl; external;
procedure glTexCoord2s(s, t: SmallInt); cdecl; external;
procedure glTexCoord2sv(var v: SmallInt); cdecl; external;
procedure glTexCoord3d(s, t, r: Double); cdecl; external;
procedure glTexCoord3dv(var v: Double); cdecl; external;
procedure glTexCoord3f(s, t, r: Single); cdecl; external;
procedure glTexCoord3fv(var v: Single); cdecl; external;
procedure glTexCoord3i(s, t, r: LongInt); cdecl; external;
procedure glTexCoord3iv(var v: LongInt); cdecl; external;
procedure glTexCoord3s(s, t, r: SmallInt); cdecl; external;
procedure glTexCoord3sv(var v: SmallInt); cdecl; external;
procedure glTexCoord4d(s, t, r, q: Double); cdecl; external;
procedure glTexCoord4dv(var v: Double); cdecl; external;
procedure glTexCoord4f(s, t, r, q: Single); cdecl; external;
procedure glTexCoord4fv(var v: Single); cdecl; external;
procedure glTexCoord4i(s, t, r, q: LongInt); cdecl; external;
procedure glTexCoord4iv(var v: LongInt); cdecl; external;
procedure glTexCoord4s(s, t, r, q: SmallInt); cdecl; external;
procedure glTexCoord4sv(var v: SmallInt); cdecl; external;
procedure glTexCoordPointer(size: LongInt; _Type: GLenum; stride: LongInt; var ptr); cdecl; external;
procedure glTexCoordPointerEXT(size: LongInt; _Type: GLenum; stride, count: LongInt; var ptr); cdecl; external;
procedure glTexEnvf(target, pname: GLenum; param: Single); cdecl; external;
procedure glTexEnvfv(target, pname: GLenum; params : PSingle); cdecl; external;
procedure glTexEnvi(target, pname: GLenum; param: LongInt); cdecl; external;
procedure glTexEnviv(target, pname: GLenum; params : PLongInt); cdecl; external;
procedure glTexGend(cord, pname: GLenum; param: Double); cdecl; external;
procedure glTexGendv(cord, pname: GLenum; params : PDouble); cdecl; external;
procedure glTexGenf(cord, pname: GLenum; param: Single); cdecl; external;
procedure glTexGenfv(cord, pname: GLenum; params : PSingle); cdecl; external;
procedure glTexGeni(cord, pname: GLenum; param: LongInt); cdecl; external;
procedure glTexGeniv(cord, pname: GLenum; params : PLongInt); cdecl; external;
procedure glTexImage1D(target: GLenum; level, internalFormat, width, border: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glTexImage2D(target: GLenum; level, internalFormat, width, height, border: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glTexImage3D(target: GLenum; level: LongInt; internalFormat: GLenum; width, height, depth, border: LongInt; format, _Type: GLEnum; var pixels); cdecl; external;
procedure glTexImage3DEXT(target: GLenum; level: LongInt; internalFormat: GLenum; width, height, depth, border: LongInt; format, _Type: GLEnum; var pixels); cdecl; external;
procedure glTexParameterf(target, pname: GLenum; param: Single); cdecl; external;
procedure glTexParameterfv(target, pname: GLenum; params : PSingle); cdecl; external;
procedure glTexParameteri(target, pname: GLenum; param: LongInt); cdecl; external;
procedure glTexParameteriv(target, pname: GLenum; params : PLongInt); cdecl; external;
procedure glTexSubImage1D(target: GLenum; level, xoffset, width: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glTexSubImage2D(target: GLenum; level, xoffset, yoffset, width, height: LongInt; format, _Type: GLenum; var pixels); cdecl; external;
procedure glTexSubImage3D(target: GLenum; level: LongInt; xoffset, yoffset, zoffset, width, height, depth: LongInt; format, _Type: GLEnum; var pixels); cdecl; external;
procedure glTexSubImage3DEXT(target: GLenum; level: LongInt; xoffset, yoffset, zoffset, width, height, depth: LongInt; format, _Type: GLEnum; var pixels); cdecl; external;
procedure glTrackMatrixNV(target: GLenum; address: GLuint; matrix, transform: GLenum); cdecl; external;
procedure glTranslated(x, y, z: Double); cdecl; external;
procedure glTranslatef(x, y, z: Single); cdecl; external;
procedure glUnlockArraysEXT; cdecl; external;
function glValidBackBufferHintAutodesk(x, y: GLint; width, height: GLsizei): GLboolean; cdecl; external;
procedure glVertex2d(x, y: Double); cdecl; external;
procedure glVertex2dv(var v: Double); cdecl; external;
procedure glVertex2f(x, y: Single); cdecl; external;
procedure glVertex2fv(var v: Single); cdecl; external;
procedure glVertex2i(x, y: LongInt); cdecl; external;
procedure glVertex2iv(var v: LongInt); cdecl; external;
procedure glVertex2s(x, y: SmallInt); cdecl; external;
procedure glVertex2sv(var v: SmallInt); cdecl; external;
procedure glVertex3d(x, y, z: Double); cdecl; external;
procedure glVertex3dv(var v: Double); cdecl; external;
procedure glVertex3f(x, y, z: Single); cdecl; external;
procedure glVertex3fv(var v: Single); cdecl; external;
procedure glVertex3i(x, y, z: LongInt); cdecl; external;
procedure glVertex3iv(var v: LongInt); cdecl; external;
procedure glVertex3s(x, y, z: SmallInt); cdecl; external;
procedure glVertex3sv(var v: SmallInt); cdecl; external;
procedure glVertex4d(x, y, z, w: Double); cdecl; external;
procedure glVertex4dv(var v: Double); cdecl; external;
procedure glVertex4f(x, y, z, w: Single); cdecl; external;
procedure glVertex4fv(var v: Single); cdecl; external;
procedure glVertex4i(x, y, z, w: LongInt); cdecl; external;
procedure glVertex4iv(var v: LongInt); cdecl; external;
procedure glVertex4s(x, y, z, w: SmallInt); cdecl; external;
procedure glVertex4sv(var v: SmallInt); cdecl; external;
procedure glVertexArrayRangeNV(size: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glVertexAttrib1dNV(index: GLuint; x: GLdouble); cdecl; external;
procedure glVertexAttrib1dvNV(index: GLuint; const v: PGLdouble); cdecl; external;
procedure glVertexAttrib1fNV(index: GLuint; x: GLfloat); cdecl; external;
procedure glVertexAttrib1fvNV(index: GLuint; const v: PGLfloat); cdecl; external;
procedure glVertexAttrib1sNV(index: GLuint; x: GLshort); cdecl; external;
procedure glVertexAttrib1svNV(index: GLuint; const v: PGLshort); cdecl; external;
procedure glVertexAttrib2dNV(index: GLuint; x, y: GLdouble); cdecl; external;
procedure glVertexAttrib2dvNV(index: GLuint; const v: PGLdouble); cdecl; external;
procedure glVertexAttrib2fNV(index: GLuint; x, y: GLfloat); cdecl; external;
procedure glVertexAttrib2fvNV(index: GLuint; const v: PGLfloat); cdecl; external;
procedure glVertexAttrib2sNV(index: GLuint; x, y: GLshort); cdecl; external;
procedure glVertexAttrib2svNV(index: GLuint; const v: PGLshort); cdecl; external;
procedure glVertexAttrib3dNV(index: GLuint; x, y, z: GLdouble); cdecl; external;
procedure glVertexAttrib3dvNV(index: GLuint; const v: PGLdouble); cdecl; external;
procedure glVertexAttrib3fNV(index: GLuint; x, y, z: GLfloat); cdecl; external;
procedure glVertexAttrib3fvNV(index: GLuint; const v: PGLfloat); cdecl; external;
procedure glVertexAttrib3sNV(index: GLuint; x, y, z: GLshort); cdecl; external;
procedure glVertexAttrib3svNV(index: GLuint; const v: PGLshort); cdecl; external;
procedure glVertexAttrib4dNV(index: GLuint; x, y, z, w: GLdouble); cdecl; external;
procedure glVertexAttrib4dvNV(index: GLuint; const v: PGLdouble); cdecl; external;
procedure glVertexAttrib4fNV(index: GLuint; x, y, z, w: GLfloat); cdecl; external;
procedure glVertexAttrib4fvNV(index: GLuint; const v: PGLfloat); cdecl; external;
procedure glVertexAttrib4sNV(index: GLuint; x, y, z, w: GLshort); cdecl; external;
procedure glVertexAttrib4svNV(index: GLuint; const v: PGLshort); cdecl; external;
procedure glVertexAttrib4ubNV(index: GLuint; x, y, z, w: GLubyte); cdecl; external;
procedure glVertexAttrib4ubvNV(index: GLuint; const v: PGLubyte); cdecl; external;
procedure glVertexAttribPointerNV(index: GLuint; fsize: GLint; _type: GLenum; stride: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glVertexAttribs1dvNV(index: GLuint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glVertexAttribs1fvNV(index: GLuint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glVertexAttribs1svNV(index: GLuint; count: GLsizei; const v: PGLshort); cdecl; external;
procedure glVertexAttribs2dvNV(index: GLuint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glVertexAttribs2fvNV(index: GLuint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glVertexAttribs2svNV(index: GLuint; count: GLsizei; const v: PGLshort); cdecl; external;
procedure glVertexAttribs3dvNV(index: GLuint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glVertexAttribs3fvNV(index: GLuint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glVertexAttribs3svNV(index: GLuint; count: GLsizei; const v: PGLshort); cdecl; external;
procedure glVertexAttribs4dvNV(index: GLuint; count: GLsizei; const v: PGLdouble); cdecl; external;
procedure glVertexAttribs4fvNV(index: GLuint; count: GLsizei; const v: PGLfloat); cdecl; external;
procedure glVertexAttribs4svNV(index: GLuint; count: GLsizei; const v: PGLshort); cdecl; external;
procedure glVertexAttribs4ubvNV(index:GLuint; count: GLsizei; const v: PGLubyte); cdecl; external;
procedure glVertexPointer(size: LongInt; _Type: GLenum; stride: LongInt; var ptr); cdecl; external;
procedure glVertexPointerEXT(size: LongInt; _Type: GLenum; stride, count: LongInt; var ptr); cdecl; external;
procedure glVertexWeightPointerEXT(size: GLsizei; _type: GLenum; stride: GLsizei; const pointer: PGLvoid); cdecl; external;
procedure glVertexWeightfEXT(weight: GLfloat); cdecl; external;
procedure glVertexWeightfvEXT(const weight: PGLfloat); cdecl; external;
procedure glViewport(x, y, width, height: LongInt); cdecl; external;
procedure glWindowBackBufferHintAutodesk; cdecl; external;
procedure glWindowPos2dARB(x, y: GLdouble); cdecl; external;
procedure glWindowPos2dvARB(const p: PGLdouble); cdecl; external;
procedure glWindowPos2fARB(x, y: GLfloat); cdecl; external;
procedure glWindowPos2fvARB(const p: PGLfloat); cdecl; external;
procedure glWindowPos2iARB(x, y: GLint); cdecl; external;
procedure glWindowPos2ivARB(const p: PGLint); cdecl; external;
procedure glWindowPos2sARB(x, y: GLshort); cdecl; external;
procedure glWindowPos2svARB(const p: PGLshort); cdecl; external;
procedure glWindowPos3dARB(x, y, z: GLdouble); cdecl; external;
procedure glWindowPos3dvARB(const p: PGLdouble); cdecl; external;
procedure glWindowPos3fARB(x, y, z: GLfloat); cdecl; external;
procedure glWindowPos3fvARB(const p: PGLfloat); cdecl; external;
procedure glWindowPos3iARB(x, y, z: GLint); cdecl; external;
procedure glWindowPos3ivARB(const p: PGLint); cdecl; external;
procedure glWindowPos3sARB(x, y, z: GLshort); cdecl; external;
procedure glWindowPos3svARB(const p: PGLshort); cdecl; external;

// =======================================================
// -------------------------------------------------------
// =======================================================

implementation



end.
{
  $Log$
  Revision 1.5  2002/05/24 07:18:15  lazarus
  MG: save is now possible during debugging

  Revision 1.4  2002/04/21 13:24:07  lazarus
  MG: small updates and fixes

  Revision 1.3  2002/04/15 10:54:58  lazarus
  MG: fixes from satan

  Revision 1.2  2001/11/12 17:36:47  lazarus
  MG: new version from satan

  Revision 1.2  2001/06/20 14:22:48  marco
   * Introduced Unix dir structure for opengl.

  Revision 1.6  2001/06/20 13:59:20  marco
   * Fixed breaking of Freebsd. Still requires copying linux to freebsd dir.

  Revision 1.5  2000/10/01 22:17:58  peter
    * new bounce demo

  Revision 1.4.2.1  2000/10/01 22:12:27  peter
    * new demo

  Revision 1.1  2000/07/13 06:34:17  michael
  + Initial import

  Revision 1.2  2000/05/31 00:34:28  alex
  made templates work

}

