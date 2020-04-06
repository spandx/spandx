# frozen_string_literal: true

RSpec.describe Spandx::Python::Pypi do
  describe '#each' do
    let(:items) { [] }

    before do
      VCR.use_cassette('pypi.org/simple', record: :new_episodes) do
        subject.each do |item|
          items.push(item)
          break if items.count == 100
        end
      end
    end

    specify { expect(items).not_to be_empty }
    specify { items.each { |item| expect(item[:name]).not_to be_nil } }
    specify { items.each { |item| expect(item[:version]).not_to match('tar.gz') } }
  end

  describe '#version_from' do
    [
      { url: 'https://files.pythonhosted.org/packages/8c/e6/83748ba1e232167de61f2bf31ec53f4b7acdd1ced52bdf3ea3366ea48132/0-0.0.0-py2.py3-none-any.whl#sha256=d8c8aeb13d410f713ea132d4268ef3dc1e113be6ec3ef2c31420df5c44e8e634', version: '0.0.0' },
      { url: 'https://files.pythonhosted.org/packages/ff/b9/6246538b88db7272f62d4eb0bd1afbb5ec402b24866be95059cc037d6970/00000a-0.0.2.tar.gz#sha256=3c1a3cdcc6cd2ca9a8dd44009509039dfa84928a4293069a74d5fc5c39e4b7a1', version: '0.0.2' },
      { url: 'https://files.pythonhosted.org/packages/a3/b4/61ad204de90c962698982b0e4aac34d4db9737041396b2c6c6860276cdf0/0.0.1-0.0.1.tar.gz#sha256=b5ebdc3ae6be725b4e8c4959790022b431e183b275dfa673a7521c2acf851d40', version: '0.0.1' },
      { url: 'https://files.pythonhosted.org/packages/79/29/f31b78d51b59eafae5b7a876e5d18870c597ca8913436f0ab4b16bc3b9fa/007-0.0.1.tar.gz#sha256=570f9b3c06b04d1e53cc9304e2a3b127731e31e7c8636df5a02aba664e618a88', version: '0.0.1' },
      { url: 'https://files.pythonhosted.org/packages/fd/49/c01735a9c8d028f22356f8e3086b412530a2f288b072945e0c079ef29bd6/007-0.0.2.tar.gz#sha256=a5f7fe73035bcd3944ac30843a595dc47a0e5d20110d70c9998f0396d104ee6c', version: '0.0.2' },
      { url: 'https://files.pythonhosted.org/packages/28/77/b367493f392d23b5e91220a92ec87aa94ca0ef4ee82b7baacc13ca48c585/00print_lol-1.0.0.tar.gz#sha256=03a146dc09b0076f2e82d39563a5b8ba93c64536609d9806be7b5b3ea87a4162', version: '1.0.0' },
      { url: 'https://files.pythonhosted.org/packages/c6/ab/4a317ae0d0c7c911f1c77719c553fc46a12d981899ceb5d47220fc3d535c/00print_lol-1.1.0.tar.gz#sha256=c452b0cc78f3a5edecbc6d160d2fa14c012d78403b0206558bcf1444eb5d1e2e', version: '1.1.0' },
      { url: 'https://files.pythonhosted.org/packages/99/b1/8329b44e81c794ebe8772531fbb94df3afb107102d183c1b0a17abb49471/0121-0.0.1.tar.gz#sha256=c340f511c652c50e67fac4e85528064f4253f5850446c9258949574a5d541f92', version: '0.0.1' },
      { url: 'https://files.pythonhosted.org/packages/95/47/2444989f005f7f3f892fc2bd375946072c23325becde4a5e2bae729579f3/01d61084-d29e-11e9-96d1-7c5cf84ffe8e-0.1.0.tar.gz#sha256=8b97d404c652de7ebc481b4ccc22c5d837d2e1d0938efcb2ce47a4220784247a', version: '0.1.0' },
      { url: 'https://files.pythonhosted.org/packages/ac/78/83c3d46cdcf616bf64b60cc35bbcc2dc9504811516e07527a4ab3af6e0c7/01d61084_d29e_11e9_96d1_7c5cf84ffe8e-0.1.0-py3-none-any.whl#sha256=258f18753542f8bb6715fdfe5691313443c92fc80b2050e36eebac81a42ec3b4', version: '0.1.0' },
      { url: 'https://files.pythonhosted.org/packages/b0/e9/0bf97f93c7fe78b0983c5d375d670bebcdb3526e6f2e60c4c7e733021c27/021-1.0.tar.gz#sha256=6ff3159b4fe981c0702437a0c3004940c623ea6cdf4efd9ac74dac094e622160', version: '1.0' },
      { url: 'https://files.pythonhosted.org/packages/b0/81/b2cb9d8fdcffdbe1988009b7fef8ec0a29cf07c8016e66a02dd9941cfe62/02exercicio-1.0.0.tar.gz#sha256=71a5ffda2437ca70bb90069155fba43bfd8694eab65d9a7875286fd955cbe02d', version: '1.0.0' },
      { url: 'https://files.pythonhosted.org/packages/ec/65/c0116953c9a3f47de89e71964d6c7b0c783b01f29fa3390584dbf3046b4d/0805nexter-1.1.0.zip#sha256=52cd128ad3afe539478abc7440d4b043384295fbe6b0958a237cb6d926465035', version: '1.1.0' },
      { url: 'https://files.pythonhosted.org/packages/c4/a0/4562cda161dc4ecbbe9e2a11eb365400c0461845c5be70d73869786809c4/0805nexter-1.2.0.zip#sha256=49785c6ae39ea511b3c253d7621c0b1b6228be2f965aca8a491e6b84126d0709', version: '1.2.0' },
      { url: 'https://files.pythonhosted.org/packages/65/3a/33138bb0c82a08a50a427a067a26310b7d6c17b0fec5e286c5d72a4f7f98/090807040506030201testpip-0.1dev.tar.gz#sha256=e32ccda7c353012cfdbf038a2e38014813442c9fbff4fade4df1901ecd2fbe17', version: '0.1dev' },
      { url: 'https://files.pythonhosted.org/packages/d3/cb/91061d33b8991125641585251a5251ac054d3bc7606cd80a0968995430c7/0-core-client-1.1.0a3.tar.gz#sha256=d47d162505074abfaed298d5463ab40e804438c59bc1d5f165b03d257c1de0ff', version: '1.1.0a3' },
      { url: 'https://files.pythonhosted.org/packages/c3/82/c0ef77f86571d9d6bdc697424cfdc3b04f6a8db6a1497b851a0f4a862401/0_core_client-1.1.0a3-py3-none-any.whl#sha256=092c89c05104a59d11ac2604c5af10cb0106bbbb521b42844dee13dd2c80606b', version: '1.1.0a3' },
      { url: 'https://files.pythonhosted.org/packages/9b/16/0160f8c9dfafb8d59e0b2eac3b0264660e8cef16e4f7dcd2da34f4073f2d/0-core-client-1.1.0a4.tar.gz#sha256=601b69c5c93d4990399ddacd79d1a81e9af3570a44a3a55bb7edff315b7c084d', version: '1.1.0a4' },
      { url: 'https://files.pythonhosted.org/packages/15/cf/129954b87fcb2a093a16c2f926bbd7600d97676df577c56fc88c955322b6/0-core-client-1.1.0a5.tar.gz#sha256=4f7c6ea029298a0343d05c1a7a136930ea78f15ecfdb9004265b758486c3a0ca', version: '1.1.0a5' },
      { url: 'https://files.pythonhosted.org/packages/28/af/8f35eed98331dd634761917747b278b5705bea44d394784bd83c6074f869/0_core_client-1.1.0a5-py3-none-any.whl#sha256=1f58f5251752a21f9e2d52239ba61b160f7c38dfac45d5206fc41b877a6e3194', version: '1.1.0a5' },
      { url: 'https://files.pythonhosted.org/packages/f5/90/897a16f3cd9044fe18a238ecaa9c421f8b54531bd7ef34e7ec405c5a319a/0-core-client-1.1.0a7.tar.gz#sha256=2f45465e53f57b6f7570aa959d27f6ab5ea32ee395e210df8de23f1335b3bcc8', version: '1.1.0a7' },
      { url: 'https://files.pythonhosted.org/packages/25/3e/d455e956af418f0632326604d19253b6d0558809ed582afffaed72200b0a/0_core_client-1.1.0a7-py3-none-any.whl#sha256=c81dfe9de503d0dc9770bf27f6177d8bf31626830b290ed5afbc0b3579f8fd2e', version: '1.1.0a7' },
      { url: 'https://files.pythonhosted.org/packages/cd/1c/52c3a1c88b2a2821ea7d2afc3c7883a8d73880dd4de4199b8d5e7d9773bd/0-core-client-1.1.0a8.tar.gz#sha256=663508e24643ad3a261b8b317e34ad6f096d2bae8997fb9155629e941b78986b', version: '1.1.0a8' },
      { url: 'https://files.pythonhosted.org/packages/66/fa/acc0e598ef7bc9af8dc67b76776fff86e163b702742c3a842d1ae7956203/0_core_client-1.1.0a8-py3-none-any.whl#sha256=3a5566dcb6d8c971c4ec74b3910b1d5b25b5e18ce6263161a1b7f9d41f3188e4', version: '1.1.0a8' },
      { url: 'https://files.pythonhosted.org/packages/78/62/2d4e6938f108aad2cf13a5b4900e371a041446402cbe8167e1900f6d1716/0lever_so-1.0.8-py2-none-any.whl#sha256=9151d51d191a66d5808269245afb8fa0c09313996d382eb320d64c53f079acb8', version: '1.0.8' },
      { url: 'https://files.pythonhosted.org/packages/0c/a7/0bb4c480f4111c80400139261abef84fa8e178b03baf0e2ae21410b4ddac/0lever_so-1.0.8-py3-none-any.whl#sha256=4b36e040be49fe7ddc7ed9a5620d35525f4eebaef9113b787d8ac77c8b2a6b27', version: '1.0.8' },
      { url: 'https://files.pythonhosted.org/packages/fd/ee/207c1511984df8cb7bb44b2de96c72b954618fe697c187eb4ef6fae1c7ad/0lever_so-1.0.9-py2-none-any.whl#sha256=abd147124d326cceb24b42eb88586ddbfbff7ff69a82380282a855a1ac30eca4', version: '1.0.9' },
      { url: 'https://files.pythonhosted.org/packages/70/ec/625463a29987be8d2c8d8d00951e66d975afb9b673b4da023f5362964096/0lever_so-1.0.9-py3-none-any.whl#sha256=f56846a01fb8e826e82a0a8e0d0ae5feec8da3f56f2f5e2069e340b25d49945a', version: '1.0.9' },
      { url: 'https://files.pythonhosted.org/packages/39/04/27b147c0d0ce31e0163d6adc6e52f64733a393ec35407d502a8e84e377fe/0lever_so-1.1.0-py2-none-any.whl#sha256=202c1db424ac7ef180a442f37c7336d99678f1481de2f443614c558b03b5ed18', version: '1.1.0' },
      { url: 'https://files.pythonhosted.org/packages/eb/fe/3832155e33dc6ff60586a6552f21eaf3214fff816ac2cae5deffae730ef2/0lever_so-1.1.0-py3-none-any.whl#sha256=06851a36f3853530971b6c21b3db38360d72f6493738ad74351ce9fbaa97e8d6', version: '1.1.0' },
      { url: 'https://files.pythonhosted.org/packages/d1/bb/1f526e72697d8ccd77c7f513ba7d1b23e45642a0ed2bb2dd49f875310c13/0lever_so-1.1.1-py2-none-any.whl#sha256=ca2347e28940daf1cd780f767a4b4bc86ba2f1ac79194552221b98cc8425d25a', version: '1.1.1' },
      { url: 'https://files.pythonhosted.org/packages/c9/3d/947b2c7b6b18b94c524384463ba255db77e36756c800406f453eac69e5f4/0lever_so-1.1.1-py3-none-any.whl#sha256=2386ed3c8da48edf47bb884bc15d6b72666e2e9232d1b3b003852371aa4fe622', version: '1.1.1' },
      { url: 'https://files.pythonhosted.org/packages/50/71/49ed67c436959dbf2d9acd36369932d8e5383a407cd1cb40b333707744b7/0lever_so-1.1.2-py2-none-any.whl#sha256=a5a0afbb41a24674259390bcdbf92a6bcd69314aa299de693fa97aa3f62b4fab', version: '1.1.2' },
      { url: 'https://files.pythonhosted.org/packages/27/ee/23aee13ec331d77b4f7e4a14546ff0030a88c5f90c1ec5b1e4ed5545d426/0lever_so-1.1.2-py3-none-any.whl#sha256=43c51847b0a8b690203bf8658616e5b10cbf127865199f5def73f967708ef2cf', version: '1.1.2' },
      { url: 'https://files.pythonhosted.org/packages/78/21/a60c322d212bdf67b0fceabd48873040a1908b6ff56ac6047ac0f61dd502/0lever_so-1.1.3-py2-none-any.whl#sha256=475e9dc19597e247b510d62bf9e11a564a03678129095ae92c97c3ff4e1ba932', version: '1.1.3' },
      { url: 'https://files.pythonhosted.org/packages/ec/75/e1d501829ca2ceb2c678fff9ff37182da5c860d16d0702f4d82a8acf7f31/0lever_so-1.2.0-py2-none-any.whl#sha256=45fd5de96b0d8a3e83e160835f72f6233ca657fa627f0c87b61cc15f6f0f845a', version: '1.2.0' },
      { url: 'https://files.pythonhosted.org/packages/39/8f/a57ca099de0406ea8567adb18ba8545bb2bdeda2073028ee74b658f841be/0lever_utils-0.0.1-py2-none-any.whl#sha256=377b2adb6e59373dfbfabdfbb90babf35d2cf761ec02e122994c20291f879691', version: '0.0.1' },
      { url: 'https://files.pythonhosted.org/packages/2e/f3/e9e87d7d80bda76d4dacfcea880274c3bbd8f8c195b02348ecf07ee0179c/0lever_utils-0.0.2-py2-none-any.whl#sha256=1e91f3df348f5d1775d2f258503daf62d92fdfdf7f2678a50c775b64350eab4d', version: '0.0.2' },
      { url: 'https://files.pythonhosted.org/packages/f0/ae/24eb23ed53ea412ec6bbf4a3f38d53773eb0bf05a46f9aa05975abb01c02/0lever_utils-0.0.2-py3-none-any.whl#sha256=49dda99e024f5af08dde0a6602ee2725fdc6e0c8eaeebbb87582c334d19a4f7c', version: '0.0.2' },
      { url: 'https://files.pythonhosted.org/packages/1d/34/ba1fa03f9db5cd5267167fd6093bc478e92a3699ca1d2fc16f6950af89c5/0lever_utils-0.0.3-py2-none-any.whl#sha256=fb4684d2026ff6bc26df92c8cf6332fe9593e55b27a6c306a3aeda5fe07179d5', version: '0.0.3' },
      { url: 'https://files.pythonhosted.org/packages/19/91/69bcda2d03734913a26469f21868d32621c624aaa82762908e2febe98ca8/0lever_utils-0.0.3-py3-none-any.whl#sha256=db0849f8f05c04ae3f4745d00355c61280b627ffc520b7cc8aa904e4fd17e097', version: '0.0.3' },
      { url: 'https://files.pythonhosted.org/packages/ea/92/b711c82299975869648a8f79bce2b28c4120e2c6088482b896110d0c0397/0lever_utils-0.0.4-py2-none-any.whl#sha256=6042aff9fc2c31eda24a004dc1b70fcaea2eb9d5901ad90327e10b924e190cf0', version: '0.0.4' },
      { url: 'https://files.pythonhosted.org/packages/f5/32/6cc29ecda3cf752556247a39bcf34d440e236f817f458ff354e1f1d0521b/0lever_utils-0.0.4-py3-none-any.whl#sha256=ff1160a666afddb87892d3c50869bddb01f6e05c35ab62825414c86fe433acec', version: '0.0.4' },
      { url: 'https://files.pythonhosted.org/packages/fa/2a/ddb55bee3ebf13139eafa0a4dc5ba151561d318138508c5282f33578f74a/0lever_utils-0.0.5-py2-none-any.whl#sha256=5516c223f26b8dd3655619976a472e653bc1679cc1db02f506a7b17c138bd649', version: '0.0.5' },
      { url: 'https://files.pythonhosted.org/packages/c4/89/09009be8d127201e3541435ac84ff57c4e3cd2213f8ae7d97f0f32cea31c/0lever_utils-0.0.5-py3-none-any.whl#sha256=4eac2c9963216b58792e5a2f5fd5e37755d82c0dd6ba1454313d92790a61fbb7', version: '0.0.5' },
      { url: 'https://files.pythonhosted.org/packages/80/f5/61a6a5f709ca20158fed62b8b8755b8765e3320860f6368487dda143a772/0lever_utils-0.0.6-py2-none-any.whl#sha256=edcfc3a5243feb2c7db3d8a19dbc629d89c583784f21edd5410be3e65ddc2e06', version: '0.0.6' },
      { url: 'https://files.pythonhosted.org/packages/70/0f/f8459388d19c9cca20d86e6453afca76567fff7405feea80de0f8e003efc/0lever_utils-0.0.6-py3-none-any.whl#sha256=29206dab46a7405ac455b6b39b7501b37c3be6728051bf35b1487c27c943fb3b', version: '0.0.6' },
      { url: 'https://files.pythonhosted.org/packages/5c/c8/9d580a308885959eb79107c7286995fe30c2b1065a04a28b9e7746788718/0lever_utils-0.0.7-py2-none-any.whl#sha256=91a8683614eedb2b3e8877fb6690965f39ed6feb3aa27e5ea9bed949b36503be', version: '0.0.7' },
      { url: 'https://files.pythonhosted.org/packages/94/65/133d48c0af2b1b7b55e5a15a5a787020d35df1046425e26b971bd35d7d52/0lever_utils-0.0.7-py3-none-any.whl#sha256=aef746f3855927e09e4090cfd16abc7d75230d2ea53c751699db073e64687ad5', version: '0.0.7' },
      { url: 'https://files.pythonhosted.org/packages/c4/9d/db08970b39a542c5f30f08aa35352174456881c60f80ec9f4b1770a5789e/0lever_utils-0.1.0-py2-none-any.whl#sha256=5a03ca33e6d9bad4ed42a6667d3d5c5fc3efef099a37ef750d34e5e5da6c49fb', version: '0.1.0' },
      { url: 'https://files.pythonhosted.org/packages/1f/c8/32dd25d1e72229a37548eba24a873c63a368714382fc6bf18a041dd212b1/0lever_utils-0.1.0-py3-none-any.whl#sha256=3a4f2eadad572878b04b2f8fc9d6bcb31550bb742b95bed0d9c568d9cc7ae5f1', version: '0.1.0' },
      { url: 'https://files.pythonhosted.org/packages/6a/c6/cedc13f810e7561247df40ba8ead02831ebf7eee2a12537c4f507e33ace1/0lever_utils-0.1.1-py2-none-any.whl#sha256=47dda1e5c1dee794bcc1ba4d5fefd6bca99cf26c11613243af77a19e40443341', version: '0.1.1' },
      { url: 'https://files.pythonhosted.org/packages/5f/6e/0954156529b22e5b1193d7413a8cdc6ad88ec1a552238956dc2e93c043a8/0lever_utils-0.1.2-py2-none-any.whl#sha256=ae47664c69e2379882a8ef7058267aace7970bd1f9c45c24bc7500aaaaa25fa3', version: '0.1.2' },
      { url: 'https://files.pythonhosted.org/packages/a0/01/63afd94765200387f5e377697b64c2ae150c7bbf97579602c0e6b5723000/0lever_utils-0.1.3-py2-none-any.whl#sha256=64b20e6ccc6bf993e4ad5b217199c88c489cf2530cee3c70333b56fce057dccf', version: '0.1.3' },
      { url: 'https://files.pythonhosted.org/packages/fe/a6/3189d263fed5988920a18c090e9f182cc32a8ded0e8df3ac86956cf41ed2/0lever_utils-0.1.4-py2-none-any.whl#sha256=8174bb227226c068ebf6fd5e845ae4193502a6488cf2ac01a9482d579161e9c8', version: '0.1.4' },
      { url: 'https://files.pythonhosted.org/packages/0c/b5/20dbb950ab388c9d7b3e5099d8956d5098a8acb02497a010b5cc21d34c0a/0lever_utils-0.1.5-py2-none-any.whl#sha256=6d12dae3ee2608fa071ca5caf76f1c2bf18519e49c4afbffdef611847b8b6aba', version: '0.1.5' },
      { url: 'https://files.pythonhosted.org/packages/01/d4/b73510e90eaace314156d4ffeddcdc32925e0ea93924c2f29266d55df475/0lever_utils-0.1.5-py3-none-any.whl#sha256=930cf8cf0edd37eb60fb0ca3760a23e5ad3c52a1295d01b73e489f2d3d0df511', version: '0.1.5' },
      { url: 'https://files.pythonhosted.org/packages/08/13/1bce760f7456e598f7156d4488a29a65419b8cf72b1004de3db459c25ba8/0lever_utils-0.1.6-py2-none-any.whl#sha256=bcdd895c07615e93dd261db391807871e3ff9898ee6ada10c5ea88a55bf04264', version: '0.1.6' },
      { url: 'https://files.pythonhosted.org/packages/f8/f3/ae0893b39b5074047ca858a4f945339effdeeed3b9cb307548af2c900492/0lever_utils-0.1.6-py3-none-any.whl#sha256=e0b63d97eacaa571f4da3ce55846b09935060b1bf60bc60d5ea1bf9c336ea766', version: '0.1.6' },
      { url: 'https://files.pythonhosted.org/packages/de/0a/742998c97b906aee0a0d4878d20c5090141fd8110f72d83d52f4c1941f67/0-orchestrator-1.1.0a0.tar.gz#sha256=bef128cef7e57e648ef6a651379793b1a63df90b4da9ffc995dd688e62ddb6d7', version: '1.1.0a0' },
      { url: 'https://files.pythonhosted.org/packages/e6/e2/813b1755dccc504d2494e924ca3253a612674379d987be606581fb297289/0_orchestrator-1.1.0a0-py3-none-any.whl#sha256=a1ba77c79f65e71fe92fe1050fe89b4fe88b9faaa3c16fe324f5da4c7e2d14e9', version: '1.1.0a0' },
      { url: 'https://files.pythonhosted.org/packages/14/19/93882065e97fe8d30b246ad47365b4a18c63846b1c8b5f294c4abcedba49/0-orchestrator-1.1.0a3.tar.gz#sha256=d9248bc9b55f645b6045f6bb4846ae0df0f7193e39633295d9967ba68665d177', version: '1.1.0a3' },
      { url: 'https://files.pythonhosted.org/packages/68/8b/bbed7b15b68637bb66fa28047b082fb5383f6ddb61ef8a723b3e46e5c4dd/0_orchestrator-1.1.0a3-py3-none-any.whl#sha256=237e32c255663a74cfc9b4f20cf69949ba10cfa52e5d3099194ad2ad35201b4c', version: '1.1.0a3' },
      { url: 'https://files.pythonhosted.org/packages/f7/c2/89c3dd8686fd4e69871e11f69f87971dd090b769450c39a6d0f002a0fcb9/0-orchestrator-1.1.0a4.tar.gz#sha256=36e8fd4b8ccd29d4f144134a5624b835749ab6d15fc85e6db5c46a7082b5303f', version: '1.1.0a4' },
      { url: 'https://files.pythonhosted.org/packages/aa/2d/a4193ef2473ec3b370e1f09beb57f161a24f7ca0fe96258f33759dda33b6/0_orchestrator-1.1.0a4-py3-none-any.whl#sha256=f3a74112dd8a2a0622c77b276ad59d483f62b6bdfce8697f1d6e0b2524860bfe', version: '1.1.0a4' },
      { url: 'https://files.pythonhosted.org/packages/82/bb/a0c60cf1a52fdaabfee3172412137ffc11fe3d4f54be7d4b9c608d5f8b20/0-orchestrator-1.1.0a5.tar.gz#sha256=21edefac10907b2ce36f07c20b01c1abc1944ab0e32989c81ad853b9f3a8f99c', version: '1.1.0a5' },
      { url: 'https://files.pythonhosted.org/packages/d4/75/06331e14b61541ac67afecb713ce6d0e3be5b52a513887c4cc74ef8bb568/0_orchestrator-1.1.0a5-py3-none-any.whl#sha256=581ee83684cb57ba5c55a0b7d3a8aa24f0ccca087b7e205d5c0ca22b47fea303', version: '1.1.0a5' },
      { url: 'https://files.pythonhosted.org/packages/f7/92/d10e965ef66b41fdad63a44899a7cb6084eaff81eb35de275ee48f10b9d5/0-orchestrator-1.1.0a7.tar.gz#sha256=2cfc80c8589f2f622db351c2aaf49136d3125318304463e9a127ad68902b9262', version: '1.1.0a7' },
      { url: 'https://files.pythonhosted.org/packages/eb/ae/8c0ce308eaed5419cc1e5b097e635c2f0d19fe94a71310e325413a58671a/0_orchestrator-1.1.0a7-py3-none-any.whl#sha256=b09acf91c50222fc64664095684c5945a8a3f9ed275739d713d4b01c8ae43746', version: '1.1.0a7' },
      { url: 'https://files.pythonhosted.org/packages/d2/5b/92b1be5d9ff54b2409b4f77d85e90f2e3bf6488d040f6f3269de0ed3aa0e/0-orchestrator-1.1.0-alpha-7-1.tar.gz#sha256=7789ed84a06a08f072ed92dfba91e46c2aab6616df80afdbdb570c017ea4852f', version: '1.1.0-alpha-7-1' },
      { url: 'https://files.pythonhosted.org/packages/0d/ce/6e7c14ebc167f31a8bb9d0b48116359794c902a60c29e0c8d197b13e8bdd/0_orchestrator-1.1.0a7.post1-py3-none-any.whl#sha256=72f076dec0cbe098ebc085fa083b30e2671a310d8186620f1c52e73c220ab81f', version: '1.1.0a7.post1' },
      { url: 'https://files.pythonhosted.org/packages/06/83/ed65c68212f5f145063ba6e3df8e8a58f724564db0f33224f3e4b567f78f/0-orchestrator-1.1.0a8.tar.gz#sha256=bf89940a3d3f3d1b8fac912cbc9b173f7ca0aa2aee623fa206771f230d0467dd', version: '1.1.0a8' },
      { url: 'https://files.pythonhosted.org/packages/21/53/f43b2f754284fe76436e06aac50c42ad984587dcfcb3e35c0999158223d5/0_orchestrator-1.1.0a8-py3-none-any.whl#sha256=5460255971955f78265894404032a33a14d3a6c93c1099d5c130b520e96d2cd9', version: '1.1.0a8' },
      { url: 'https://files.pythonhosted.org/packages/33/c0/d82e190c0b6284b1d0bdd8493f11edf3a80ed601b92c44dacc0dd4b43648/0wdg9nbmpm-0.1.tar.gz#sha256=7130b1f19df69c3dc91b99fa3b31ebae873ef93b3d601285dbd3b3f97271d625', version: '0.1' },
      { url: 'https://files.pythonhosted.org/packages/34/fc/f4a8a1569c906c325d0b41d5b3ac6d115bb1fa860ec46362cf61cf649495/0x-0.1.tar.gz#sha256=4d3f4ad49c37166c79d33f8c58c92558d0f044336248f70296661a046a9b5f1b', version: '0.1' },
      { url: 'https://files.pythonhosted.org/packages/df/4a/170d68a650f57aea9bda4a814642301504f750385891f56ed0d9d2c46cc7/0x01-autocert-dns-aliyun-0.1.tar.gz#sha256=f3ceaa3f0b8c3ffe10705b890f2a96dabc64e2923debbaa4908eb939efd49499', version: '0.1' },
      { url: 'https://files.pythonhosted.org/packages/0d/9f/a24c516016770a80bb33dffd852762fe8e61a5127d94b4bdb290003a6b6a/0x01-letsencrypt-0.1.tar.gz#sha256=3b6786a2f24382ea7b42bbc543c2fce70c4fe4c0de49a24c1098cb41e271526e', version: '0.1' },
      { url: 'https://files.pythonhosted.org/packages/b9/24/6526bbe0e479f4272887998feb7e801f10d37a3e325fd129da448f795211/0x10c-asm-0.0.1.tar.gz#sha256=6d4c95c53b4c989d9a26d16b21d643bff1c40c9e1b213d6a800616d04eee0d18', version: '0.0.1' },
      { url: 'https://files.pythonhosted.org/packages/e1/3a/6588c9c52a06e64a903314bc810ca712c3fc6c27b86779c057e23e7512b6/0x10c-asm-0.0.2.tar.gz#sha256=e4703f8bd0a44c473469ce6b57d4dde3c7acbf7e6c2df75d83570ae94fb08d6f', version: '0.0.2' },
      { url: 'https://files.pythonhosted.org/packages/31/94/3f5aead5e720ab41e7a6d6ecd247bb5f72f4ad0706d3b622c967474ddc64/0x-contract-addresses-2.0.0.tar.gz#sha256=5df5c618005262df882094d72af31c7a390ce21e8f9d235d008ccf2a311a8125', version: '2.0.0' },
      { url: 'https://files.pythonhosted.org/packages/23/b0/55c18ecf8e093fb0c08024ad7d2559d4023639259692d9dd01e5ffcd30e3/0x_contract_addresses-2.0.0-py3-none-any.whl#sha256=f285f96d401eb13f572343dc4f658689b745642a66e0767ecea94e0d3be629ac', version: '2.0.0' },
      { url: 'https://files.pythonhosted.org/packages/c3/72/441451eb853fca52c8630b3d0cd6c555e135621ae07810fd688ee9d05b2b/0x-contract-addresses-2.0.1.tar.gz#sha256=df8280ebf1abaa0e62ea8872c1ca93b7329b117df930ab32be478405712b4630', version: '2.0.1' },
      { url: 'https://files.pythonhosted.org/packages/fe/ec/0c4b906147bfdb09ede4deff7489ea33267daf14f6d8c9706ed1b1ac3597/0x_contract_addresses-2.0.1-py3-none-any.whl#sha256=0514f73c92694bbeee2704374fcd2f0eefbe8bbdfc43dd95dc0ab6c262d4c058', version: '2.0.1' },
      { url: 'https://files.pythonhosted.org/packages/47/52/d189b2c6d2954effaf12960b8916b9d62fb8150083a42ef9b5e62462ac32/0x-contract-addresses-2.1.0.tar.gz#sha256=d1df84b35d9a35b73c1054c090942e31ff152526249d8d251c7b2fc684e045ab', version: '2.1.0' },
      { url: 'https://files.pythonhosted.org/packages/0e/e7/2bc27a48170fc7d4f458fda9d9ff973f1780bf1b0fa2fd71de89124d7014/0x_contract_addresses-2.1.0-py3-none-any.whl#sha256=dd78dd0429bac1ff88e1d1bf5422f9f17d7738e1fa49da97755056792d9f5945', version: '2.1.0' },
      { url: 'https://files.pythonhosted.org/packages/ed/e2/23a769ee1845baa615fcfa20f540844b95193111c8c9317f3840ecf764de/0x-contract-addresses-2.2.0.tar.gz#sha256=b9cc6fc7210e8c2e0bb3154d0cdd65fa747145ceb3a388a0146a781b029f6617', version: '2.2.0' },
      { url: 'https://files.pythonhosted.org/packages/fa/f5/7a29cb2377058c738d29bb9232168fdea17d94801fbace3e90054e2139de/0x_contract_addresses-2.2.0-py3-none-any.whl#sha256=4cc518ee16bd06cc8bfc531fd54b3da905dc17ac59b66d52b66e27ccbdb151cc', version: '2.2.0' },
      { url: 'https://files.pythonhosted.org/packages/ab/c1/3962bef93118a862cb38f3fc3b1f9e6d3acfb8e1fff64879d2c54463b258/0x-contract-addresses-3.0.0.dev0.tar.gz#sha256=5a9a21d2c76ff6a10cbb9573d239a487e8e4cb90620d6e6806f72f6e6bf6a12a', version: '3.0.0.dev0' },
      { url: 'https://files.pythonhosted.org/packages/fd/51/a7a8468a4bc226a4e96fda87acfb36bde1582b04c4435d4fb56dce2cd0d6/0x_contract_addresses-3.0.0.dev0-py3-none-any.whl#sha256=cbe05e7827fe3e6b44e237fccbed3803bf881f4bfaf195043d2b472606dbd148', version: '3.0.0.dev0' },
      { url: 'https://files.pythonhosted.org/packages/84/f5/53e108fd0c64063620fac17858f359973e236c71b35729997287540aee1d/0x-contract-addresses-3.0.0.dev1.tar.gz#sha256=eed2f645e3f7990fd286ef73888b301d3413ca2efaada7e791bcd7100a58b9c2', version: '3.0.0.dev1' },
      { url: 'https://files.pythonhosted.org/packages/4b/f7/90b5cf54de20704b5e09247594ed656e7511b8dea12ae6fea177ede9c700/0x_contract_addresses-3.0.0.dev1-py3-none-any.whl#sha256=1d045c6733b727a965470933e4184494636d3ab07675681c3e65ccef80eb721d', version: '3.0.0.dev1' },
      { url: 'https://files.pythonhosted.org/packages/74/77/2a5ccb2440d54b7a87e5716206c973ea329232c3a74f06860ad2fa979a67/0x-contract-addresses-3.0.0.dev2.tar.gz#sha256=6759639fcbcfc577a727145dbfa08faf5115d5729858cdb1e508510ed0dfdc87', version: '3.0.0.dev2' },
      { url: 'https://files.pythonhosted.org/packages/d9/f0/151d0f3bb569e3496ff6edbe8705ce077ac765aea80f8922f16c5d8376c4/0x_contract_addresses-3.0.0.dev2-py3-none-any.whl#sha256=001df466ee9c04c2379357f361c6ac55ec155dcf0da2e89c91a4d58b1fce481d', version: '3.0.0.dev2' },
      { url: 'https://files.pythonhosted.org/packages/76/f7/c6971f37fe7890d8747f8e7de1c2613a75c154d3f05aca0f88fe7d0c0ff9/0x-contract-addresses-3.0.0.dev3.tar.gz#sha256=31fa7d3598fd9667a9d747287cc3c531e0f0fb5999e198903b6f681edbd8f270', version: '3.0.0.dev3' },
      { url: 'https://files.pythonhosted.org/packages/5d/be/460cab4688fa1025c65ecba1f3d56264faa0319ee3ad6e38475f8125aca1/0x_contract_addresses-3.0.0.dev3-py3-none-any.whl#sha256=63f47a7735e5bdf089a2d87c469540b58ce82f10bae4ae076fac25a5f5e9f02c', version: '3.0.0.dev3' },
      { url: 'https://files.pythonhosted.org/packages/48/fa/2bfa40b043c9539b12aed4ff6fee834c8bbdeacf3e8388842d2fef0d1b84/0x-contract-addresses-3.0.0.tar.gz#sha256=677f7390d6505b85647af3dfa4765c307a26344d94716d263993c1f7efbf88d8', version: '3.0.0' },
      { url: 'https://files.pythonhosted.org/packages/ba/a1/568bdbb82f1ae8a283f147c31deca9cea2e9cc7d47e4227681d71c55dda4/0x_contract_addresses-3.0.0-py3-none-any.whl#sha256=7ca9f02bfc9fb1ea7368f929dd9f90bef2baaa996642de45ab2304f7c914bec0', version: '3.0.0' },
      { url: 'https://files.pythonhosted.org/packages/56/79/2f81c26461433b3036cd34d396325c38ade3a9aa64e6636540b67bc084d4/0x-contract-artifacts-2.0.0.tar.gz#sha256=7c1a0b4204cf08f46efad2b1a19d19e2d6189e1bea9e220e41caa0f145159316', version: '2.0.0' },
      { url: 'https://files.pythonhosted.org/packages/4b/ab/1df6cee9478914fc9119e9f7fe0463d4a57e63149aa70c496cce48457c07/0x_contract_artifacts-2.0.0-py3-none-any.whl#sha256=44146561e762958fcae64b0202da3416b78a3780f0265a4b57f7e3b6af26b120', version: '2.0.0' },
      { url: 'https://files.pythonhosted.org/packages/94/68/acdf5c33b26f88186bd3f40d912d7388a8b6a10437f33ec85c49deb3b550/0x-contract-artifacts-3.0.0.dev0.tar.gz#sha256=fd9a55411968b844a3a81bcae1167682f31dd304adbbc6f720d1c7b43aaf6acd', version: '3.0.0.dev0' },
      { url: 'https://files.pythonhosted.org/packages/d2/5b/92b1be5d9ff54b2409b4f77d85e90f2e3bf6488d040f6f3269de0ed3aa0e/0-orchestrator-1.1.0-alpha-7-1.tar.gz#sha256=7789ed84a06a08f072ed92dfba91e46c2aab6616df80afdbdb570c017ea4852f', version: '1.1.0-alpha-7-1' },
    ].each do |item|
      specify { expect(subject.version_from(item[:url])).to eql(item[:version]) }
    end
  end

  describe '#definition_for' do
    subject { described_class.new }

    let(:source) { 'pypi.org' }
    let(:package) { 'six' }
    let(:version) { '1.13.0' }
    let(:successful_response_body) do
      JSON.generate(
        info: {
          name: package,
          version: version
        }
      )
    end

    context 'when the default source is reachable' do
      before do
        stub_request(:get, "https://#{source}/pypi/#{package}/#{version}/json")
          .to_return(status: 200, body: successful_response_body)
      end

      specify do
        expect(subject.definition_for(package, version)).to include(
          'name' => package,
          'version' => version
        )
      end
    end

    context 'when the response redirects to a different location' do
      let(:redirect_url) { "https://#{source}/pypi/#{SecureRandom.uuid}" }

      before do
        stub_request(:get, "https://#{source}/pypi/#{package}/#{version}/json")
          .to_return(status: 301, headers: { 'Location' => redirect_url })

        stub_request(:get, redirect_url)
          .to_return(status: 200, body: successful_response_body)
      end

      specify do
        expect(subject.definition_for(package, version)).to include(
          'name' => package,
          'version' => version
        )
      end
    end

    context 'when stuck in an infinite redirect loop' do
      before do
        url = "https://#{source}/pypi/#{package}/#{version}/json"

        11.times do |n|
          redirect_url = "#{url}#{n}"
          stub_request(:get, url)
            .to_return(status: 301, headers: { 'Location' => redirect_url })
          url = redirect_url
        end
      end

      it 'gives up after `n` attempts' do
        expect(subject.definition_for(package, version)).to be_empty
      end
    end

    context 'when the source is not reachable' do
      before do
        stub_request(:get, "https://#{source}/pypi/#{package}/#{version}/json")
          .to_timeout
      end

      it 'fails gracefully' do
        expect(subject.definition_for(package, version)).to be_empty
      end
    end
  end
end
