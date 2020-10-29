import 'dart:ffi' as ffi;

typedef GetMethodPropertyFunc = ffi.Uint32 Function(
    ffi.Uint32 index, ffi.Uint64 propID, ffi.Pointer value);
typedef GetNumberOfMethodsFunc = ffi.Uint32 Function(ffi.Pointer numMethods);
typedef GetNumberOfFormatsFunc = ffi.Uint32 Function(ffi.Pointer numFormats);
typedef GetHandlerPropertyFunc = ffi.Uint32 Function(
    ffi.Uint64 propID, ffi.Pointer value);
typedef GetHandlerPropertyFunc2 = ffi.Uint32 Function(
    ffi.Uint32 index, ffi.Uint64 propID, ffi.Pointer value);
typedef CreateObjectFunc = ffi.Uint32 Function(
    ffi.Pointer clsID, ffi.Pointer iid, ffi.Pointer outObject);
typedef SetLargePageModeFunc = ffi.Uint32 Function();

typedef GetMethodPropertyFuncDart = int Function(
    int index, int propID, ffi.Pointer value);
typedef GetNumberOfMethodsFuncDart = int Function(ffi.Pointer numMethods);
typedef GetNumberOfFormatsFuncDart = int Function(ffi.Pointer numFormats);
typedef GetHandlerPropertyFuncDart = int Function(
    int propID, ffi.Pointer value);
typedef GetHandlerPropertyFunc2Dart = int Function(
    int index, int propID, ffi.Pointer value);
typedef CreateObjectFuncDart = int Function(
    ffi.Pointer clsID, ffi.Pointer iid, ffi.Pointer outObject);
typedef SetLargePageModeFuncDart = int Function();

final lib7z = ffi.DynamicLibrary.open(r'C:\Program Files\7-Zip\7z.dll');
final rGetMethodProperty =
    lib7z.lookupFunction<GetMethodPropertyFunc, GetMethodPropertyFuncDart>(
        'GetMethodProperty');
final rGetNumberOfMethods =
    lib7z.lookupFunction<GetNumberOfMethodsFunc, GetNumberOfMethodsFuncDart>(
        'GetNumberOfMethods');
final rGetNumberOfFormats =
    lib7z.lookupFunction<GetNumberOfFormatsFunc, GetNumberOfFormatsFuncDart>(
        'GetNumberOfFormats');
final rGetHandlerProperty =
    lib7z.lookupFunction<GetHandlerPropertyFunc, GetHandlerPropertyFuncDart>(
        'GetHandlerProperty');
final rGetHandlerProperty2 =
    lib7z.lookupFunction<GetHandlerPropertyFunc2, GetHandlerPropertyFunc2Dart>(
        'GetHandlerProperty2');
final rCreateObject = lib7z
    .lookupFunction<CreateObjectFunc, CreateObjectFuncDart>('CreateObject');
final rSetLargePageMode =
    lib7z.lookupFunction<SetLargePageModeFunc, SetLargePageModeFuncDart>(
        'SetLargePageMode');
main(List<String> args) {}
