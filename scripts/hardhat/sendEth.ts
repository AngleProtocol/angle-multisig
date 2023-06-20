import { submit, execute } from './submitTx'

async function main() {
  const baseTxn = {
    to: '0x65671d573fC0E62139fBdE470bfD03a38B4D5F26',
    value: '100000000000000000',
    data: '0x',
    operation: '0', /// 0 is call, 1 is delegate call
  }

  await submit(baseTxn)
  /*
  await execute(
    baseTxn,
    '0xb0e53771f1ab7e025f1d92e803e5001f63a99b8dd529c462899839872d935f60',
  )
  */
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
