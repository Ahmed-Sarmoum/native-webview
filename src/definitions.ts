export interface NativeWebiewPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
